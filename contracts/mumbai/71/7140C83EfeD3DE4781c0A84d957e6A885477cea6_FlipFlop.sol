// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "../Deposit.sol";
import "../Withdraw.sol";
import "../OptionsVault.sol";
import "../PerformanceFee.sol";
import "../storage/Storage.sol";

contract FlipFlop is Deposit, Withdraw, OptionsVault, PerformanceFee {
    constructor() {
        _disableInitializers();
    }

    function initFlipFlop(
        address _asset1,
        address _asset2,
        address _fundamentalVault1,
        address _fundamentalVault2,
        address _chainLinkPriceOracle,
        bool _isReverseQuote,
        address _additionalChainLinkPriceOracle,
        bool _isReverseAdditionalQuote,
        address _whiteList
    ) external initializer {
        require(_whiteList != ZERO_ADDRESS, "WhiteList should be set");
        //init BaseDoubleLinkedList
        init(115);
        //OZ-contracts initialization
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        initDeposit(
            _asset1,
            _asset2,
            _fundamentalVault1,
            _fundamentalVault2,
            _chainLinkPriceOracle,
            _isReverseQuote,
            _additionalChainLinkPriceOracle,
            _isReverseAdditionalQuote
        );
        whiteList = IMasterWhitelist(whiteList);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ShareMath} from "../../libraries/ShareMath.sol";
import "../../libraries/Vault.sol";
import "../../interfaces/IERC20Detailed.sol";
import "../../interfaces/IWMATIC.sol";
import "../../interfaces/ITrufinThetaVault.sol";
import "./storage/Storage.sol";
import "./helpers/UserDoubleLinkedList.sol";

/// @title Deposit
/// @notice Contract covers users deposit functionality
contract Deposit is Storage, UserDoubleLinkedList {
    using SafeERC20 for IERC20;

    /// @notice Polygon ChainLink's oracles:
    /// @notice usdc/eth - 0xefb7e6be8356cCc6827799B6A7348eE674A80EaE
    /// @notice matic/usd - 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
    /// @notice wbtc/usd - 0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6
    /// @notice usdc/usd - 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7

    /// @notice Mumbai ChainLink's oracles:
    /// @notice eth/usd - 0x0715A7794a1dc8e42615F059dD6e406A6594651A
    /// @notice matic/usd - 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
    /// @notice btc/usd - 0x007A22900a3B98143368Bd5906f8E17e9867581b
    /// @notice usdc/usd - 0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0

    AggregatorV3Interface public chainLinkPriceOracle;
    /// @notice if we don't have price oracle asset1/asset2 or asset2/asset1, we can use additional price oracle
    /// @notice so, if we have asset1/asset3 price oracle and additional asset3/asset2 price oracle, we can calc
    /// @notice asset1/asset2 = (asset1/asset3) * (asset3/asset2)
    AggregatorV3Interface public additionalChainLinkPriceOracle;

    /// @notice when we have price feed asset2/asset1 instead of asset1/asset2, this flag should be set to true
    bool public isReverseQuote;

    /// @notice when we have additional price feed asset2/asset1 instead of asset1/asset2, this flag should be set to
    /// @notice true
    bool public isReverseAdditionalQuote;

    /// @dev address of WMATIC contract
    address private WMATIC;

    /// @dev price divider for some price mul and div operations
    uint256 private priceDivider;

    /// @dev price multiplier for some price mul and div operations
    uint256 private priceMultiplier;

    /// @notice oracle decimals
    /// @dev saved with purpose to avoid external calls every time when it is needed
    uint8 public oracleDecimals;

    /// @notice additional oracle decimals
    /// @dev saved with purpose to avoid external calls every time when it is needed
    uint8 public additionalOracleDecimals;

    address private constant WMATIC_POLYGON =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    //self-deployed:
    address private constant WMATIC_MUMBAI =
        0xf40440705AFD9a524409BF53B158E4A62bBFAB56;

    /// @dev event which is emitted when new cap's parameters are set
    event CapChanged(
        uint256 _newMinDepositOfAsset1,
        uint256 _newMaxCapOfAsset1,
        uint256 _newMinDepositOfAsset2,
        uint256 _newMaxCapOfAsset2
    );

    /// @dev event which is emitted when new oracles are set
    event OracleChanged(
        address _chainLinkPriceOracle,
        address _additionalChainLinkPriceOracle
    );

    /// @dev event which is emitted when a new deposit occurs
    event Deposited(
        address indexed _user,
        uint256 _amountOfAsset1,
        uint256 _amountOfAsset2
    );

    /// @dev init the contract. Should be call from main contract in the initializer function
    /// @param _asset1 - address of asset1
    /// @param _asset2 - address of asset2
    /// @param _fundamentalVault1 - address of the fundamental Vault1
    /// @param _fundamentalVault2 - address of the fundamental Vault2
    /// @param _chainLinkPriceOracle - address of the chainLink oracle;
    /// @param _isReverseQuote - indicates that the price of the chainLink oracle should be inverted
    /// @param _additionalChainLinkPriceOracle - address of an additional chainLink oracle if it is needed
    /// @param _isReverseAdditionalQuote -indicates that the price of the additional chainLink oracle should be
    /// inverted
    function initDeposit(
        address _asset1,
        address _asset2,
        address _fundamentalVault1,
        address _fundamentalVault2,
        address _chainLinkPriceOracle,
        bool _isReverseQuote,
        address _additionalChainLinkPriceOracle,
        bool _isReverseAdditionalQuote
    ) internal {
        require(
            (_asset1 != ZERO_ADDRESS) && (_asset2 != ZERO_ADDRESS),
            "Asset should not be zero_address"
        );
        require(
            (_fundamentalVault1 != ZERO_ADDRESS) &&
                (_fundamentalVault2 != ZERO_ADDRESS),
            "FundamentalVault should not be zero_address"
        );
        //init BaseDoubleLinkedList
        init(115);
        //read parameters of the fundamental vault1;
        Vault.VaultParams memory vaultParams1 = ITrufinThetaVault(
            _fundamentalVault1
        ).vaultParams();
        //read parameters of the fundamental vault2;
        Vault.VaultParams memory vaultParams2 = ITrufinThetaVault(
            _fundamentalVault2
        ).vaultParams();
        require(
            vaultParams1.underlying == vaultParams2.underlying,
            "FundamentalVaults should have same underlying asset"
        );
        require(
            vaultParams1.isPut != vaultParams2.isPut,
            "FundamentalVaults should be put and call"
        );

        fundamentalVault1 = ITrufinThetaVault(_fundamentalVault1);
        fundamentalVault2 = ITrufinThetaVault(_fundamentalVault2);

        asset1 = _asset1;
        asset2 = _asset2;
        //read decimals of asset1
        decimalsOfAsset1 = IERC20Detailed(_asset1).decimals();
        //read decimals of asset2
        decimalsOfAsset2 = IERC20Detailed(_asset2).decimals();
        setChainLinkOracles(
            _chainLinkPriceOracle,
            _isReverseQuote,
            _additionalChainLinkPriceOracle,
            _isReverseAdditionalQuote
        );
        setWMATIC();
    }

    /// @notice set up new chainLink oracle(s). Only the owner can call this function
    /// @param _chainLinkPriceOracle - address of achainLink oracle;
    /// @param _isReverseQuote - indicates that the price of the chainLink oracle should be inverted
    /// @param _additionalChainLinkPriceOracle - address of an additional chainLink oracle if it needs
    /// @param _isReverseAdditionalQuote -indicates that the price of the additional chainLink oracle should be
    /// inverted
    function setChainLinkOracles(
        address _chainLinkPriceOracle,
        bool _isReverseQuote,
        address _additionalChainLinkPriceOracle,
        bool _isReverseAdditionalQuote
    ) public onlyOwner {
        require(
            _chainLinkPriceOracle != ZERO_ADDRESS,
            "ChainLink Price Oracle shouldn't be ZERO_ADDRESS"
        );
        chainLinkPriceOracle = AggregatorV3Interface(_chainLinkPriceOracle);
        isReverseQuote = _isReverseQuote;
        //read oracle's decimals
        oracleDecimals = chainLinkPriceOracle.decimals();
        //as we operate uint104 for fundamental vaults,
        //max oracle decimals = log10(2^104) = log2(2^104)/log2(10) = ~104/3 = ~34
        require(oracleDecimals < 34, "Oracle has too much decimals");
        //if decimals of asset1 plus oracle's decimals more than decimals of asset, it means that when we mul amount
        //of asset1 on oracle price (=getting of amount of asset2) we will have too much decimals and we need to divide
        //result on the appropriate divider to get right decimals of asset2. Otherwise, we should mul instead of div.
        if (decimalsOfAsset1 + oracleDecimals > decimalsOfAsset2) {
            priceDivider =
                10**(decimalsOfAsset1 + oracleDecimals - decimalsOfAsset2);
            priceMultiplier = 0;
        } else {
            priceDivider = 0;
            priceMultiplier =
                10**(decimalsOfAsset2 - oracleDecimals - decimalsOfAsset1);
        }
        additionalChainLinkPriceOracle = AggregatorV3Interface(
            _additionalChainLinkPriceOracle
        );
        isReverseAdditionalQuote = _isReverseAdditionalQuote;
        //if an additional chainLink price oracle is set
        if (_additionalChainLinkPriceOracle != ZERO_ADDRESS) {
            //read decimals of the additional price oracle
            additionalOracleDecimals = additionalChainLinkPriceOracle.decimals();
            require(
                additionalOracleDecimals < 34,
                "Additional oracle has too much decimals"
            );
        }
        emit OracleChanged(
            _chainLinkPriceOracle,
            _additionalChainLinkPriceOracle
        );
    }

    /// @notice deposit native Matic if the Vault accepts Matic.
    /// @dev Matic can be accepted if asset1 or asset2 equal WMATIC. Function doesn't work if the contract is paused
    function depositMATIC() external payable {
        _depositMATIC(msg.sender);
    }

    /// @notice deposit native Matic as a creditor to a debtor if vault accepts Matic
    /// @dev Matic can be accepted if asset1 or asset2 equal WMATIC. Function doesn't work if the contract is paused
    /// @param _toUser - the debtor address
    function depositMATICFor(address _toUser) external payable {
        _depositMATIC(_toUser);
    }

    /// @notice deposit assets into the Vault. Function doesn't work if the contract is paused. Appropriate amount of
    /// asset1 and asset2 should be approved to the contract to allow transfer
    /// @param _asset1Amount - deposited amount of asset1. Amount of asset2 will be calculated using chainLink
    /// oracle(s)
    function deposit(uint256 _asset1Amount) external {
        _deposit(msg.sender, msg.sender, _asset1Amount);
    }

    /// @notice deposit assets as a creditor to a debtor into the Vault. Function doesn't work if the contract is
    /// @notice paused. Appropriate amount of asset1 and asset2 should be approved to the contract to allow transfer
    /// @param _asset1Amount - deposited amount of asset1. Amount of asset2 will be calculated using chainLink oracle(s)
    function depositFor(address _forUser, uint256 _asset1Amount) external {
        _deposit(msg.sender, _forUser, _asset1Amount);
    }

    /// @notice set Cap params. Function can be called only by the owner
    /// @param _minDepositOfAsset1 - min accepted amount of a deposit of asset1
    /// @param _maxCapOfAsset1 - max cap of the Vault for asset1
    /// @param _minDepositOfAsset2 - min accepted amount of a deposit of asset2
    /// @param _maxCapOfAsset2 - max cap of the Vault for asset2
    function setCap(
        uint256 _minDepositOfAsset1,
        uint256 _maxCapOfAsset1,
        uint256 _minDepositOfAsset2,
        uint256 _maxCapOfAsset2
    ) external onlyOwner {
        require(
            (_maxCapOfAsset1 != 0) &&
                (_maxCapOfAsset2 != 0) &&
                (_minDepositOfAsset1 != 0) &&
                (_minDepositOfAsset2 != 0),
            "All input parameters shoudn't be zero!"
        );

        require(
            (_minDepositOfAsset1 <= _maxCapOfAsset1) &&
                (_minDepositOfAsset2 <= _maxCapOfAsset2),
            "minDeposit shouldn't exceed maxCap"
        );
        //Fundamental Vaults don't accept amounts which exceed uint104
        ShareMath.assertUint104(_maxCapOfAsset1);
        ShareMath.assertUint104(_maxCapOfAsset2);
        ShareMath.assertUint104(_minDepositOfAsset1);
        ShareMath.assertUint104(_minDepositOfAsset2);
        maxCapOfAsset1 = _maxCapOfAsset1;
        maxCapOfAsset2 = _maxCapOfAsset2;
        minDepositOfAsset1 = _minDepositOfAsset1;
        minDepositOfAsset2 = _minDepositOfAsset2;
        emit CapChanged(
            _minDepositOfAsset1,
            _maxCapOfAsset1,
            _minDepositOfAsset2,
            _maxCapOfAsset2
        );
    }

    /// @notice get spot price of asset1/asset2
    /// @dev function takes account of if an oracle price should be inverted, including additional oracle if it is set
    /// @return spot price with oracle decimals
    function getSpotPrice() public view virtual returns (uint256) {
        //get the oracle price
        (, int256 price, , , ) = chainLinkPriceOracle.latestRoundData();
        require(price > 0, "Oracle returned non-positive price!");
        uint256 uPrice = uint256(price);
        //if the oracle price should be inverted
        if (isReverseQuote) {
            //invert the oracle price
            uPrice = inversePrice(uPrice);
        }
        //if an additional oracle is set
        if (address(additionalChainLinkPriceOracle) != ZERO_ADDRESS) {
            //get the additional oracle price
            (, int256 additionalPrice, , , ) = additionalChainLinkPriceOracle
                .latestRoundData();
            require(
                additionalPrice > 0,
                "Additional oracle returned non-positive price!"
            );

            uint256 uAdditionalPrice = uint256(additionalPrice);
            //if the additional oracle price should be inverted
            if (isReverseAdditionalQuote) {
                //invert the additional oracle price
                uAdditionalPrice = inversePrice(uAdditionalPrice);
            }
            //set final price. We need to remove additionalOracleDecimals because this decimals were added during mul
            uPrice =
                (uPrice * uAdditionalPrice) /
                (10**additionalOracleDecimals);
        }
        return uPrice;
    }

    /// @dev set WMATIC address which depends on current chainid()
    function setWMATIC() private {
        uint256 id;
        assembly {
            id := chainid()
        }

        if (id == 137) {
            WMATIC = WMATIC_POLYGON;
        } else if (id == 80001) {
            WMATIC = WMATIC_MUMBAI;
        } else {
            revert("Unsupported chain");
        }
    }

    /// @notice deposit native Matic if vault accepts Matic
    /// @dev Matic can be accepted if asset1 or asset2 equal WMATIC
    /// @param _toUser - to whom this deposit
    function _depositMATIC(address _toUser) private whenNotPaused nonReentrant {
        require(
            whiteList.isUserWhitelisted(msg.sender),
            "Sender should be whitelisted"
        );
        require(
            whiteList.isUserWhitelisted(_toUser),
            "Debtor should be whitelisted"
        );
        require(
            (asset1 == WMATIC) || (asset2 == WMATIC),
            "Vault doesn't accept MATIC"
        );
        bool asset1IsMATIC = asset1 == WMATIC;
        require(
            (asset1IsMATIC && (msg.value >= minDepositOfAsset1)) ||
                (!asset1IsMATIC && (msg.value >= minDepositOfAsset2)),
            "Amount of MATIC less then minimum deposit"
        );
        require(
            (asset1IsMATIC &&
                (msg.value + totalAmountOfAsset1 <= maxCapOfAsset1)) ||
                (!asset1IsMATIC &&
                    (msg.value + totalAmountOfAsset2 <= maxCapOfAsset2)),
            "Amount of MATIC exceeds Vault maximum cap"
        );
        uint256 amountOfAssetToDeposit;
        //if asset1 == WMATIC
        if (asset1IsMATIC) {
            //it is a simple case to get amount of asset2 - just mul on spotPrice and bring the result to asset2
            //decimals
            amountOfAssetToDeposit = getSpotPrice() * msg.value;
            if (priceDivider > 0) {
                amountOfAssetToDeposit /= priceDivider;
            } else {
                amountOfAssetToDeposit *= priceMultiplier;
            }
            _depositAsset(asset2, msg.sender, amountOfAssetToDeposit);
        } else {
            //asset2 == WMATIC, so we have something like usdc/matic => matic = usdc * rate => usdc => matic / rate
            if (decimalsOfAsset2 < decimalsOfAsset1) {
                amountOfAssetToDeposit =
                    (msg.value *
                        10 **
                            (oracleDecimals <<
                                (1 + decimalsOfAsset1 - decimalsOfAsset2))) /
                    getSpotPrice() /
                    10**oracleDecimals;
            } else {
                amountOfAssetToDeposit =
                    (msg.value * 10**(oracleDecimals << 1)) /
                    getSpotPrice() /
                    10**(oracleDecimals + decimalsOfAsset2 - decimalsOfAsset1);
            }
            _depositAsset(asset1, msg.sender, amountOfAssetToDeposit);
        }

        uint256 balanceOfMATIC = IERC20(WMATIC).balanceOf(address(this));
        //wrap Matic
        IWMATIC(WMATIC).deposit{value: msg.value}();
        require(
            IERC20(WMATIC).balanceOf(address(this)) - balanceOfMATIC >=
                msg.value,
            "Something wrong with WMATIC wrapping"
        );
        //update the user info
        updateUser(
            _toUser,
            asset1IsMATIC ? msg.value : amountOfAssetToDeposit,
            asset1IsMATIC ? amountOfAssetToDeposit : msg.value
        );
        //update the Vault info
        updateVaultWithIncreasedAmount(
            asset1IsMATIC ? msg.value : amountOfAssetToDeposit,
            asset1IsMATIC ? amountOfAssetToDeposit : msg.value
        );
        emit Deposited(
            _toUser,
            asset1IsMATIC ? msg.value : amountOfAssetToDeposit,
            asset1IsMATIC ? amountOfAssetToDeposit : msg.value
        );
    }

    /// @dev function just increase the global total amount of assets of the Vault
    /// @param _amountOfAsset1ToDeposit - amount of asset1 which was added
    /// @param _amountOfAsset2ToDeposit - amount of asset2 which was added
    function updateVaultWithIncreasedAmount(
        uint256 _amountOfAsset1ToDeposit,
        uint256 _amountOfAsset2ToDeposit
    ) private {
        totalAmountOfAsset1 += _amountOfAsset1ToDeposit;
        totalAmountOfAsset2 += _amountOfAsset2ToDeposit;
    }

    /// @dev erc20 transfer the asset into the Vault
    /// @param asset - address of the asset
    /// @param _user - from user
    /// @param _amountOfAsset - how much
    function _depositAsset(
        address asset,
        address _user,
        uint256 _amountOfAsset
    ) private {
        bool isAsset1 = asset1 == asset;
        require(
            _amountOfAsset >=
                (isAsset1 ? minDepositOfAsset1 : minDepositOfAsset2),
            "Amount of asset less then minimum deposit"
        );
        require(
            _amountOfAsset +
                (asset1 == asset ? totalAmountOfAsset1 : totalAmountOfAsset2) <=
                (isAsset1 ? maxCapOfAsset1 : maxCapOfAsset2),
            "Amount of asset exceeds Vault maximum cap"
        );
        uint256 balanceOfAsset = IERC20(asset).balanceOf(address(this));
        //need to be approved by the user
        IERC20(asset).safeTransferFrom(_user, address(this), _amountOfAsset);
        require(
            IERC20(asset).balanceOf(address(this)) - _amountOfAsset >=
                balanceOfAsset,
            "Something wrong with token transfer"
        );
    }

    /// @dev deposit funds from the creditor to the debitor's account in the Vault
    /// @param _fromUser - debitor
    /// @param _toUser - creditor
    /// @param _amountOfAsset1 - amount of asset1. Amount of asset2 will be calculated using the oracle
    function _deposit(
        address _fromUser,
        address _toUser,
        uint256 _amountOfAsset1
    ) private whenNotPaused nonReentrant {
        require(
            whiteList.isUserWhitelisted(_fromUser),
            "Sender should be whitelisted"
        );
        require(
            whiteList.isUserWhitelisted(_toUser),
            "Debtor should be whitelisted"
        );
        //transfer _amountOfAsset from _fromUser to the Vault;
        _depositAsset(asset1, _fromUser, _amountOfAsset1);
        //calculate amountOfAsset2
        uint256 amountOfAsset2 = getSpotPrice() * _amountOfAsset1;
        if (priceDivider > 0) {
            amountOfAsset2 /= priceDivider;
        } else {
            amountOfAsset2 *= priceMultiplier;
        }
        //transfer amountOfAsset2 from _fromUser to the Vault
        _depositAsset(asset2, _fromUser, amountOfAsset2);
        //update _toUser User structure with additional amount of asset
        updateUser(_toUser, _amountOfAsset1, amountOfAsset2);
        //update the global amount of assets
        updateVaultWithIncreasedAmount(_amountOfAsset1, amountOfAsset2);
        emit Deposited(_toUser, _amountOfAsset1, amountOfAsset2);
    }

    /// @dev update User structure or create new if _user isn't in the list. Amount of assets is added to exist
    /// @param _user - user to update
    /// @param _amountOfAsset1 - amount of asset1 to add
    /// @param _amountOfAsset2 - amount of asset2 to add
    function updateUser(
        address _user,
        uint256 _amountOfAsset1,
        uint256 _amountOfAsset2
    ) private {
        //get existing user or empty User structure
        User memory user = getUser(_user);
        user.amountOfAsset1 += _amountOfAsset1;
        user.amountOfAsset2 += _amountOfAsset2;
        user.user = _user;
        //save the user
        putUser(user);
    }

    /// @dev calc inversePrice = 1/_price
    /// @param _price - price to invert
    /// @return inversePrice with oracleDecimals
    function inversePrice(uint256 _price) private view returns (uint256) {
        //we should do price = 1\_price
        //we will return value with same decimals as oracleDecimals
        //so inverseOne = 10 ** oracleDecimals
        //but price can be very close to inverseOne as calculated above
        //(for instance, price = 99999999, reverseOne = 100000000)
        //so, only reverseOne is not enough
        //we introduce mult = 10 ** (oracleDecimals * 2)
        return ((10**(oracleDecimals << 1)) / _price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IERC20Detailed.sol";
import "./Deposit.sol";

/// @notice Contract covers users withdrawals

contract Withdraw is Deposit {
    using SafeERC20 for IERC20;

    /// @dev event which is emitted when a new withdrawal happens
    /// @param _user - who withdrew
    /// @param _asset1Amount - amount of asset1 which was withdrawn
    /// @param _asset2Amount - amount of asset2 which was withdrawn
    event WithdrawCurrentBalance(
        address indexed _user,
        uint256 _asset1Amount,
        uint256 _asset2Amount
    );

    /// @dev event which is emitted when a new queued withdrawal happens. One of _queuedAmountOfAsset1 or
    /// @dev _queuedAmountOfAsset2 should be zero
    /// @param _user - who made a queued withdrawal
    /// @param _queuedAmountOfAsset1 - queued amount of asset1 which is wanted to withdraw
    /// @param _queuedAmountOfAsset2 - queued amount of asset2 which is wanted to withdraw
    event QueuedWithdraw(
        address indexed _user,
        uint256 _queuedAmountOfAsset1,
        uint256 _queuedAmountOfAsset2
    );

    /// @dev event which is emitted when queued withdrawal completes
    /// @param _user - who completed withdrawal
    /// @param _asset1Amount - amount of asset1 which was withdrawn
    /// @param _asset2Amount - amount of asset2 which was withdrawn
    event CompleteQueuedWithdraw(
        address indexed _user,
        uint256 _asset1Amount,
        uint256 _asset2Amount
    );

    /// @dev event which is emitted when emergency withdrawal happens
    /// @param _owner - the owner, who made an emergency withdrawal
    /// @param _asset1Amount - amount of asset1 which was withdrawn
    /// @param _asset2Amount - amount of asset2 which was withdrawn
    /// @param _nativeCoinAmount - amount of the native coin which was withdrawn
    event EmergencyWithdrawal(
        address indexed _owner,
        uint256 _asset1Amount,
        uint256 _asset2Amount,
        uint256 _nativeCoinAmount
    );

    /// @notice Withdraw balance which was deposited in the current round. Both assets will be withdrawn but only one
    /// @notice amount used as the input parameter. Amount of other asset will be calculated using the proportion of
    /// @notice the "first" asset to withdraw to the "first" asset in the user account in the Vault.
    /// @notice Function doesn't work when the contract is paused
    /// @param _assetToWithdraw - what asset to withdraw
    /// @param _amountOfAssetToWithdraw - how much of asset to withdraw

    //actually, we don't need nonReentrant here, because all interaction will be done at the end
    //however, it can be added just in case
    function withdrawCurrentBalance(
        address _assetToWithdraw,
        uint256 _amountOfAssetToWithdraw
    )
        external
        /*nonReentrant*/
        whenNotPaused
    {
        require(
            _amountOfAssetToWithdraw > 0,
            "Withdrawal amount should be positive"
        );
        require(
            whiteList.isUserWhitelisted(msg.sender),
            "Sender should be whitelisted"
        );
        bool isFirstAsset = _assetToWithdraw == asset1;
        require(
            isFirstAsset || (_assetToWithdraw == asset2),
            "Incorrect asset to withdraw"
        );
        User memory user = getUser(msg.sender);
        //both amounts should be non zero by design
        require(
            user.amountOfAsset1 * user.amountOfAsset2 > 0,
            "You don't have funds to withdraw"
        );
        //calc amount of asset1 to withdraw
        uint256 amountOfAsset1ToWithdraw = isFirstAsset
            ? _amountOfAssetToWithdraw
            : (user.amountOfAsset1 * _amountOfAssetToWithdraw) /
                user.amountOfAsset2;
        //if after withdrawing the amount of asset1 remains less than min deposit of asset1
        if (
            user.amountOfAsset1 < minDepositOfAsset1 + amountOfAsset1ToWithdraw
        ) {
            //we will withdraw all user's funds of asset1
            amountOfAsset1ToWithdraw = user.amountOfAsset1;
        }
        //calc amount of asset2 to withdraw
        uint256 amountOfAsset2ToWithdraw = isFirstAsset
            ? (user.amountOfAsset2 * amountOfAsset1ToWithdraw) /
                user.amountOfAsset1
            : _amountOfAssetToWithdraw;
        //if after withdrawing the amount of asset1 remains less than min deposit of asset1
        if (
            user.amountOfAsset2 < minDepositOfAsset2 + amountOfAsset2ToWithdraw
        ) {
            //we will withdraw all user's funds of asset2
            amountOfAsset2ToWithdraw = user.amountOfAsset2;
            //and all user's funds of asset1 (because, during prev calculation of amounOfAsset1ToWithdraw, this amount
            //can be not equal user.amountOfAsset1, but Vault's logic is designed to work with 2 assets, not only one,
            //so, both asset should be withdrawn in full amount)
            amountOfAsset1ToWithdraw = user.amountOfAsset1;
        }
        //if the user withdraws all funds and doesn't have any options
        if (
            (user.amountOfAsset1 == amountOfAsset1ToWithdraw) &&
            (user.numberOfSharesOfFundamentalVault1 == 0) &&
            (user.numberOfSharesOfFundamentalVault2 == 0) &&
            (user.queuedAmountOfAsset1ToWithdraw == 0) &&
            (user.queuedAmountOfAsset2ToWithdraw == 0)
        ) {
            //this user will be removed from the Vault
            removeUser(msg.sender);
        } else {
            //else just update the user's User structure with new value of remaining funds
            user.amountOfAsset1 -= amountOfAsset1ToWithdraw;
            user.amountOfAsset2 -= amountOfAsset2ToWithdraw;
            putUser(user);
        }
        totalAmountOfAsset1 -= amountOfAsset1ToWithdraw;
        totalAmountOfAsset2 -= amountOfAsset2ToWithdraw;
        IERC20(asset1).safeTransfer(msg.sender, amountOfAsset1ToWithdraw);
        IERC20(asset2).safeTransfer(msg.sender, amountOfAsset2ToWithdraw);
        emit WithdrawCurrentBalance(
            msg.sender,
            amountOfAsset1ToWithdraw,
            amountOfAsset2ToWithdraw
        );
    }

    /// @dev function just decreases the global total amount of assets of the Vault
    /// @param _amountOfAsset1ToWithdraw - amount of asset1 which was added
    /// @param _amountOfAsset2ToWithdraw - amount of asset2 which was added
    function updateVaultWithDecreasedAmount(
        uint256 _amountOfAsset1ToWithdraw,
        uint256 _amountOfAsset2ToWithdraw
    ) private {
        totalAmountOfAsset1 -= _amountOfAsset1ToWithdraw;
        totalAmountOfAsset2 -= _amountOfAsset2ToWithdraw;
    }

    /// @notice initiates queued withdrawal. Function replaces previous amount to withdraw if it exists. Function allows
    /// @notice to pass more _amountOfAssetToWithdraw then stored currently. If after expiration
    /// @notice _amountOfAssetToWithdraw still will be more than allowed, the maximum allowed amount will be withdrawn.
    /// @notice Function allows to withdraw a small amount if the account will still hold more than a min deposit.
    /// @notice Function doesn't work when the contract is paused
    /// @param _assetToWithdraw - which asset is queued (during completeWithdraw all calculations will be done
    /// relatively to this asset)
    /// @param _amountOfAssetToWithdraw - requested amount of asset to withdraw
    function initiateWithdraw(
        address _assetToWithdraw,
        uint256 _amountOfAssetToWithdraw
    ) external whenNotPaused {
        require(
            _amountOfAssetToWithdraw > 0,
            "_amountOfAssetToWithraw should be positive"
        );
        require(
            whiteList.isUserWhitelisted(msg.sender),
            "Sender should be whitelisted"
        );
        bool isAsset1 = _assetToWithdraw == asset1;
        require(
            isAsset1 || (_assetToWithdraw == asset2),
            "Wrong asset to withdraw"
        );
        User memory user = getUser(msg.sender);
        require(user.user != ZERO_ADDRESS, "User doesn't have deposit");
        //to simplify things, only one of queuedAmountOfAsset1ToWithdraw and queuedAmountOfAsset2ToWithdraw can be
        //non-zero. So, if the user call initiateWithdraw with asset1 and after than call initiateWithdraw with
        //asset2 - completeWithdraw will be based on asset2
        user.queuedAmountOfAsset1ToWithdraw = isAsset1
            ? _amountOfAssetToWithdraw
            : 0;
        user.queuedAmountOfAsset2ToWithdraw = isAsset1
            ? 0
            : _amountOfAssetToWithdraw;
        //save the current round. We need this to understand during completeWithdraw, that options were expired (the
        //round will be more than currentRound)
        user.roundWhenQueuedWithdrawalWasRequested = currentRound;
        //save the user
        putUser(user);
        emit QueuedWithdraw(
            msg.sender,
            user.queuedAmountOfAsset1ToWithdraw,
            user.queuedAmountOfAsset2ToWithdraw
        );
    }

    /// @notice Complete queued withdrawal, should be called after round when initiateWithdraw happened. If the
    /// @notice requested amount will be less than actual, the amount of the "second" asset will be returned in
    /// @notice proportion based on requested_amount_of_requested_asset/actual_amount_of_requested_asset. Function
    /// @notice doesn't work when contract is paused

    //actually we don't need nonReentrant here, because of check-effect-interaction pattern is applied
    function completeWithdraw()
        external
        /*nonReentrant*/
        whenNotPaused
    {
        require(
            whiteList.isUserWhitelisted(msg.sender),
            "Sender should be whitelisted"
        );
        User memory user = getUser(msg.sender);
        require(user.user != ZERO_ADDRESS, "User doesn't have deposit");
        require(
            (user.queuedAmountOfAsset1ToWithdraw > 0) ||
                (user.queuedAmountOfAsset2ToWithdraw > 0),
            "Queued withdraw wasn't requested in the previous round"
        );
        require(
            user.roundWhenQueuedWithdrawalWasRequested < currentRound,
            "Withdraw can be done after end of the current round"
        );
        //get amounts to withdraw
        (
            uint256 amountOfAsset1ToWithdraw,
            uint256 amountOfAsset2ToWithdraw
        ) = calcLockedAmount(
                user.queuedAmountOfAsset1ToWithdraw,
                user.amountOfAsset1,
                user.queuedAmountOfAsset2ToWithdraw,
                user.amountOfAsset2
            );
        require(amountOfAsset1ToWithdraw > 0, "Nothing to withdraw");

        //if all funds will be withdrawn and the user doesn't have other funds in options
        if (
            (user.amountOfAsset1 == amountOfAsset1ToWithdraw) &&
            (user.numberOfSharesOfFundamentalVault1 == 0)
        ) {
            //remove the user from the Vault
            removeUser(msg.sender);
        } else {
            //else update the user's User structure
            user.amountOfAsset1 -= amountOfAsset1ToWithdraw;
            user.amountOfAsset2 -= amountOfAsset2ToWithdraw;
            user.queuedAmountOfAsset1ToWithdraw = 0;
            user.queuedAmountOfAsset2ToWithdraw = 0;
            //save the user
            putUser(user);
        }
        //update total amount of the Vault assets
        updateVaultWithDecreasedAmount(
            amountOfAsset1ToWithdraw,
            amountOfAsset2ToWithdraw
        );
        //make erc20-transfer from the Vault to the user
        IERC20(asset1).safeTransfer(msg.sender, amountOfAsset1ToWithdraw);
        IERC20(asset2).safeTransfer(msg.sender, amountOfAsset2ToWithdraw);
        emit CompleteQueuedWithdraw(
            msg.sender,
            amountOfAsset1ToWithdraw,
            amountOfAsset2ToWithdraw
        );
    }

    /// @dev calculates amounts to withdraw or locked amount (which should not be used for option writing)
    /// @param _queuedAmountOfAsset1ToWithdraw - requested amount of asset1 to withdraw
    /// @param _amountOfAsset1 - actual amount of asset1
    /// @param _queuedAmountOfAsset2ToWithdraw - requested amount of asset2 to withdraw
    /// @param _amountOfAsset2 - actual amount of asset2
    /// @return amounts which can (will) be withdrawn
    function calcLockedAmount(
        uint256 _queuedAmountOfAsset1ToWithdraw,
        uint256 _amountOfAsset1,
        uint256 _queuedAmountOfAsset2ToWithdraw,
        uint256 _amountOfAsset2
    ) internal view returns (uint256, uint256) {
        //if there is no requested amount
        if (
            //this condition should never work
            (_queuedAmountOfAsset1ToWithdraw *
                _queuedAmountOfAsset2ToWithdraw !=
                0) ||
            (_queuedAmountOfAsset1ToWithdraw +
                _queuedAmountOfAsset2ToWithdraw ==
                0)
        ) {
            //returns zeroes
            return (0, 0);
        }
        uint256 amountOfAsset1ToWithdraw;
        uint256 amountOfAsset2ToWithdraw;
        //if asset1 was requested
        if (_queuedAmountOfAsset1ToWithdraw > 0) {
            //if after withdrawal/locking, the amount of asset1 remains less than min deposit of asset1 - withdraw all
            //funds
            amountOfAsset1ToWithdraw = _amountOfAsset1 <
                minDepositOfAsset1 + _queuedAmountOfAsset1ToWithdraw
                ? _amountOfAsset1
                : _queuedAmountOfAsset1ToWithdraw;
            //calc the amount of asset2 to withdraw/lock
            amountOfAsset2ToWithdraw =
                (_amountOfAsset2 * amountOfAsset1ToWithdraw) /
                _amountOfAsset1;
            //if after withdrawal/locking, the amount of asset2 remains less than min deposit of asset2
            if (
                _amountOfAsset2 < amountOfAsset2ToWithdraw + minDepositOfAsset2
            ) {
                //withdraw all funds
                amountOfAsset2ToWithdraw = _amountOfAsset2;
                //also a whole amount of asset2, because above amountOfAsset1ToWithdraw can be not equal _amountOfAsset1
                amountOfAsset1ToWithdraw = _amountOfAsset1;
            }
        } else {
            //asset2 was requested
            //if after withdrawal/locking, the amount of asset2 remains less than min deposit of asset2 - withdraw all
            //funds
            amountOfAsset2ToWithdraw = _amountOfAsset2 <
                minDepositOfAsset2 + _queuedAmountOfAsset2ToWithdraw
                ? _amountOfAsset2
                : _queuedAmountOfAsset2ToWithdraw;
            //calc the amount of asset1 to withdraw/lock
            amountOfAsset1ToWithdraw =
                (_amountOfAsset1 * amountOfAsset2ToWithdraw) /
                _amountOfAsset2;
            //if after withdrawal/locking, the amount of asset1 remains less than min deposit of asset1
            if (
                _amountOfAsset1 < minDepositOfAsset1 + amountOfAsset1ToWithdraw
            ) {
                //withdraw all funds
                amountOfAsset1ToWithdraw = _amountOfAsset1;
                //also a whole amount of asset1, because above amountOfAsset2ToWithdraw can be not equal _amountOfAsset2
                amountOfAsset2ToWithdraw = _amountOfAsset2;
            }
        }
        return (amountOfAsset1ToWithdraw, amountOfAsset2ToWithdraw);
    }

    /// @notice emergency withdraw all funds of the Vault to the owner. Only the owner can call this function
    function emergencyWithdraw() external onlyOwner {
        uint256 assetOneAmount = IERC20(asset1).balanceOf(address(this));
        uint256 assetTwoAmount = IERC20(asset2).balanceOf(address(this));

        if (assetOneAmount > 0) {
            IERC20(asset1).safeTransfer(msg.sender, assetOneAmount);
        }
        if (assetTwoAmount > 0) {
            IERC20(asset2).safeTransfer(msg.sender, assetTwoAmount);
        }

        uint256 nativeCoinAmount = address(this).balance;
        if (nativeCoinAmount > 0) {
            bool sent = payable(msg.sender).send(nativeCoinAmount);
            require(sent, "Failed to send Matic");
        }

        emit EmergencyWithdrawal(
            msg.sender,
            assetOneAmount,
            assetTwoAmount,
            nativeCoinAmount
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.14;

import "../../libraries/ShareMath.sol";
import "../../libraries/Compute.sol";
import "./Withdraw.sol";
import "hardhat/console.sol";

contract OptionsVault is Withdraw {
    using Compute for uint256;
    uint256 oldETHPreSwap;
    uint256 oldUSDCPreSwap;
    /// @notice number of iterations to do per call while assigning shares
    uint256 public shareAssignUserSize;
    /// @notice price per share
    uint256 public pps = 10**18;
    /// @notice epoch status
    bool isEpochInProgress = false;

    event InternalSwapComputation(
        uint256 asset1OldPrice,
        uint256 asset1NewPrice,
        uint256 asset2OldPrice,
        uint256 asset2NewPrice
    );

    event StartEpoch(
        uint256 amountOfAsset1,
        uint256 amounOfAsset2,
        address fundamentalVault1,
        address fundamentalVault2
    );

    event UpdateUserShares(
        uint256 amountOfAsset1Used,
        uint256 amountOfAsset2Used,
        uint256 sharesMinted
    );

    /// @notice Function called post swap to compute the vaults new Asset1 amount and Asset2 amount
    /// @param A_S The amount of asset actually swapped by the swap vault ( parameter fetched via swap vault )
    /// @param S1 The amount at which the real swap took place with the MM.
    // add only swap vault role , called post the funds are send from swap contract to flipflop
    function internalSwapComputationPostSwap(uint256 A_S, uint256 S1)
        external
        onlyOwner
    {
        require(totalAmountOfAsset1 > 0, "Insufficient Asset 1");
        require(totalAmountOfAsset2 > 0, "Insufficient Asset 2");
        require(S1 > 0, "S1 Cannot be 0");

        uint256 totalAmountOfAsset1Before = totalAmountOfAsset1;
        uint256 totalAmountOfAsset2Before = totalAmountOfAsset2;

        totalAmountOfAsset1 = totalAmountOfAsset1Before - A_S;

        totalAmountOfAsset2 =
            totalAmountOfAsset2Before +
            Compute.scaleDecimals(
                (S1 * A_S),
                decimalsOfAsset1,
                decimalsOfAsset2
            ) /
            2;

        oldETHPreSwap = totalAmountOfAsset1Before;
        oldUSDCPreSwap = totalAmountOfAsset2Before;

        emit InternalSwapComputation(
            oldETHPreSwap,
            totalAmountOfAsset1,
            oldUSDCPreSwap,
            totalAmountOfAsset2
        );
    }

    /// @notice View function that returns the vaults current asset1/asset2 ratio in the desired output decimals
    /// @param _outDecimals the number of decimals in the output
    /// @return : Value of the computed ratio
    function ratioCompute(uint8 _outDecimals) public view returns (uint256) {
        return
            Compute.divPrice(
                totalAmountOfAsset1,
                decimalsOfAsset1,
                totalAmountOfAsset2,
                decimalsOfAsset2,
                _outDecimals
            );
    }

    /// @notice Helper function to approve spending of assets of this vault by fundamental vaults
    function _approveAssetSpending() external onlyOwner {
        IERC20(asset1).approve(address(fundamentalVault1), totalAmountOfAsset1);
        IERC20(asset2).approve(address(fundamentalVault2), totalAmountOfAsset2);
    }

    // *************
    //  Epoch Start
    // *************

    /// @notice Deposits the funds to fundamental vaults. Readjusts the vault positions. Withdrawls are done before this is called.
    function startEpoch() public nonReentrant onlyOwner {
        // transfer to fundamental vaults
        fundamentalVault1.deposit(totalAmountOfAsset1);
        fundamentalVault2.deposit(totalAmountOfAsset2);

        e_V = totalAmountOfAsset1;
        u_V = totalAmountOfAsset2;
        totalAmountOfAsset1 = 0;
        totalAmountOfAsset2 = 0;

        isEpochInProgress = true;

        emit StartEpoch(
            totalAmountOfAsset1,
            totalAmountOfAsset2,
            address(fundamentalVault1),
            address(fundamentalVault2)
        );
    }

    /// @notice for minting new user position post swap and deposit to fundamental vaults
    /// @param S - The internal swap price
    /// @param S1 - The external swap price
    /// @param S2 - The midway market price
    /// @param A - The amount of asset 1 or 2 that is send to the vault for swap
    /// @param A_S - The amount of asset 1 or 2 that actually got swapped
    /// @return _toContinue The next address mint shares to.
    function startMint(
        uint256 S,
        uint256 S1,
        uint256 S2,
        uint256 A,
        uint256 A_S
    ) public onlyOwner nonReentrant returns (address _toContinue) {
        require(isEpochInProgress, "Epoch not started yet");

        UserDoubleLinkedList.User memory user = getFirstUser();
        for (uint8 i = 0; i < shareAssignUserSize; i++) {
            _assignUserShares(user, S, S1, S2, A, A_S);
            user = getNextUser();
        }
        return user.user;
    }

    /// @notice for continue minting of new user positions post swap and deposit to fundamental vaults
    /// @param _startFrom The address to start the position readjustment from
    /// @param S - The internal swap price
    /// @param S1 - The external swap price
    /// @param S2 - The midway market price
    /// @param A - The amount of asset 1 or 2 that is send to the vault for swap
    /// @param A_S - The amount of asset 1 or 2 that actually got swapped
    /// @return _toContinue The next address mint shares to.
    function continueMint(
        address _startFrom,
        uint256 S,
        uint256 S1,
        uint256 S2,
        uint256 A,
        uint256 A_S
    ) public onlyOwner nonReentrant returns (address _toContinue) {
        UserDoubleLinkedList.User memory user = getUser(_startFrom);
        uint8 i = 0;
        while (user.user != address(0) && i < shareAssignUserSize) {
            _assignUserShares(user, S, S1, S2, A, A_S);
            user = getNextUser();
            i++;
        }
        return user.user;
    }

    /// @notice Internal function that actually comprises of calculating the number of shares for each user
    /// @param user - The user to whom shares are to be minted
    /// @param S - The internal swap price
    /// @param S1 - The external swap price
    /// @param S2 - The midway market price
    /// @param A - The amount of asset 1 or 2 that is send to the vault for swap
    /// @param A_S - The amount of asset 1 or 2 that actually got swapped
    function _assignUserShares(
        UserDoubleLinkedList.User memory user,
        uint256 S,
        uint256 S1,
        uint256 S2,
        uint256 A,
        uint256 A_S
    ) internal {
        (uint256 e1, uint256 u1) = _computeNewDepositValues(
            S,
            S1,
            A,
            A_S,
            user
        );

        UserDoubleLinkedList.User memory globalUser = User(
            e_V,
            u_V,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            address(this),
            0,
            0,
            0,
            0,
            0
        );

        (uint256 e2, uint256 u2) = _computeNewDepositValues(
            S,
            S1,
            A,
            A_S,
            globalUser
        );

        // n→10^18* (u1(e,u,S,S1)+S2*e1(e,u,S,S1)+(n/n_T)* (u1(e_V,u_V,S,S1)+S2*e1(e_V,u_V,S,S1)))/(U1+S2*E1)
        uint256 userNumberOfShares = user.numberOfShares.wadDiv(n_T);

        uint256 S2xe1 = S2.wadMul(e1);
        uint256 n = 10**18 *
            (u1 +
                Compute.scaleDecimals(
                    S2xe1,
                    decimalsOfAsset1,
                    decimalsOfAsset2
                ) +
                (userNumberOfShares.wadMul(u2)) +
                (
                    Compute.scaleDecimals(
                        (S2.wadMul(e2)),
                        decimalsOfAsset1,
                        decimalsOfAsset2
                    )
                )).wadDiv(
                    totalAmountOfAsset2 +
                        Compute.scaleDecimals(
                            (S2.wadMul(totalAmountOfAsset1)),
                            decimalsOfAsset1,
                            decimalsOfAsset2
                        )
                );

        emit UpdateUserShares(user.amountOfAsset1, user.amountOfAsset2, n);

        user.amountOfAsset1 = 0;
        user.amountOfAsset2 = 0;
        user.numberOfShares = n;
        putUser(user);
    }

    /// @notice Internal function to check which asset is in excess, asset 1 or asset 2
    /// @param S The internal swap rate
    /// @param E The amount of Asset 1
    /// @param U The amount of Asset 2
    /// @return : Weather S*E > U or not
    function _isAsset1PriceGreaterThanAsset2(
        uint256 S,
        uint256 E,
        uint256 U
    ) internal view returns (bool) {
        return
            Compute.scaleDecimals(
                S.wadMul(E),
                decimalsOfAsset1,
                decimalsOfAsset2
            ) > U;
    }

    /// @notice Computes A, weather it will be asset 1 which will be swapped, or asset 2 which will get swapped
    /// @param S The internal swap rate
    /// @return A The final value A to be send to swap vault
    /// @return decimals The number of decimals for A
    function computeA(uint256 S)
        public
        view
        returns (uint256 A, uint8 decimals)
    {
        uint256 E = totalAmountOfAsset1;
        uint256 U = totalAmountOfAsset2;

        if (_isAsset1PriceGreaterThanAsset2(S, E, U)) {
            A =
                (E -
                    Compute.scaleDecimals(
                        (U.wadDiv(S)),
                        decimalsOfAsset2,
                        decimalsOfAsset1
                    )) /
                2;

            decimals = decimalsOfAsset1;
        } else {
            A =
                (U -
                    Compute.scaleDecimals(
                        S.wadMul(E),
                        decimalsOfAsset1,
                        decimalsOfAsset2
                    )) /
                2;
            decimals = decimalsOfAsset2;
        }
    }

    /// @notice Internal function that does the new asset1 and asset2 position calculations for the user
    /// @param S - The internal swap price
    /// @param S1 - The external swap price
    /// @param A - The amount of asset 1 or 2 that is send to the vault for swap
    /// @param A_S - The amount of asset 1 or 2 that actually got swapped
    /// @param user - User object of the user whose positions needs to be recalculated
    function _computeNewDepositValues(
        uint256 S,
        uint256 S1,
        uint256 A,
        uint256 A_S,
        UserDoubleLinkedList.User memory user
    ) internal returns (uint256, uint256) {
        require(user.user != address(0), "User address is address(0)");

        (
            uint256 amountOfAsset1ToWithdraw,
            uint256 amountOfAsset2ToWithdraw
        ) = calcLockedAmount(
                user.queuedAmountOfAsset1ToWithdraw,
                user.amountOfAsset1,
                user.queuedAmountOfAsset2ToWithdraw,
                user.amountOfAsset2
            );

        require(S > 0, "S cant be less than or equal to 0");
        require(S1 > 0, "S1 can't be less than or equal to 0");
        require(
            user.amountOfAsset1 > 0 || amountOfAsset1ToWithdraw == 0,
            "Amount Of Asset 1 is 0 and withdraw amount of asset 1 is greater than 0"
        );
        require(
            user.amountOfAsset2 > 0 || amountOfAsset2ToWithdraw == 0,
            "Amount Of Asset 2 is 0 and withdraw amount of asset 2 is greater than 0"
        );
        require(S_E > 0, "S_E == 0");
        require(S_U > 0, "S_U == 0");

        uint256 e = user.amountOfAsset1 - amountOfAsset1ToWithdraw;
        uint256 u = user.amountOfAsset2 - amountOfAsset2ToWithdraw;

        if (
            !_isAsset1PriceGreaterThanAsset2(
                S,
                totalAmountOfAsset1,
                totalAmountOfAsset2
            )
        ) {
            A = Compute.scaleDecimals(
                A.wadDiv(S1),
                decimalsOfAsset2,
                decimalsOfAsset1
            );
            A_S = Compute.scaleDecimals(
                A_S.wadDiv(S1),
                decimalsOfAsset2,
                decimalsOfAsset1
            );
        }

        if (_isAsset1PriceGreaterThanAsset2(S, oldETHPreSwap, oldUSDCPreSwap)) {
            uint256 UbyS = Compute.scaleDecimals(
                u.wadDiv(S),
                decimalsOfAsset2,
                decimalsOfAsset1
            );

            if (_isAsset1PriceGreaterThanAsset2(S, e, u)) {
                require(S_E > A, "S_E < A");
                uint256 stack = S1.wadMul(A_S);
                {
                    uint256 SmulS_E = S.wadMul(S_E - A);
                    stack = stack.wadDiv(S_E);
                    stack = (SmulS_E).wadDiv(S_E) + stack;
                }
                uint256 S_EMinusA = S_E - A + A_S;

                user.amountOfAsset1 =
                    e -
                    ((e - UbyS).wadMul(S_EMinusA).wadDiv(S_E)) /
                    2;

                user.amountOfAsset2 =
                    u +
                    Compute.scaleDecimals(
                        (e - UbyS).wadMul(stack),
                        decimalsOfAsset1,
                        decimalsOfAsset2
                    ) /
                    2;
            } else {
                user.amountOfAsset1 =
                    e +
                    (Compute.scaleDecimals(
                        u.wadDiv(S),
                        decimalsOfAsset2,
                        decimalsOfAsset1
                    ) - e) /
                    2;
                user.amountOfAsset2 =
                    u -
                    (u -
                        Compute.scaleDecimals(
                            e.wadMul(S),
                            decimalsOfAsset1,
                            decimalsOfAsset2
                        )) /
                    2;
            }
        } else {
            uint256 EtoU = Compute.scaleDecimals(
                e.wadMul(S),
                decimalsOfAsset1,
                decimalsOfAsset2
            );
            if (_isAsset1PriceGreaterThanAsset2(S, e, u)) {
                user.amountOfAsset1 =
                    e -
                    (e -
                        Compute.scaleDecimals(
                            u.wadDiv(S),
                            decimalsOfAsset2,
                            decimalsOfAsset1
                        )) /
                    2;

                user.amountOfAsset2 =
                    u +
                    (Compute.scaleDecimals(
                        e.wadMul(S),
                        decimalsOfAsset1,
                        decimalsOfAsset2
                    ) - u) /
                    2;
            } else {
                uint256 stack;

                {
                    uint256 S_UToAsset1 = Compute.scaleDecimals(
                        (S_U.wadMul(S1)),
                        decimalsOfAsset2,
                        decimalsOfAsset1
                    );

                    uint256 divValue = S_U.wadMul(S);

                    stack = (Compute.scaleDecimals(
                        S_U,
                        decimalsOfAsset2,
                        decimalsOfAsset1
                    ) - A).wadDiv(divValue);

                    stack += A_S.wadDiv(S_UToAsset1);
                }

                uint256 AToAsset2 = Compute.scaleDecimals(
                    A - A_S,
                    decimalsOfAsset1,
                    decimalsOfAsset2
                );

                user.amountOfAsset1 =
                    e +
                    (Compute.scaleDecimals(
                        (((u - EtoU).wadMul(stack))),
                        decimalsOfAsset2,
                        decimalsOfAsset1
                    ) / 2);

                uint256 EXS = (
                    Compute.scaleDecimals(
                        EtoU,
                        decimalsOfAsset1,
                        decimalsOfAsset2
                    )
                );

                user.amountOfAsset2 =
                    u -
                    ((u - EXS).wadMul(S_U - AToAsset2)).wadDiv(S_U) /
                    2;
            }
        }

        user.amountOfAsset1 += amountOfAsset1ToWithdraw;
        user.amountOfAsset2 += amountOfAsset2ToWithdraw;

        putUser(user);

        return (user.amountOfAsset1, user.amountOfAsset2);
    }

    /// @notice Schedule withdraw from fundamental vaults
    /// @dev only owner function
    // it doesn't work, reason - the same as in the startEpoch
    function scheduleWithdrawFromFundamentalVaults()
        public
        nonReentrant
        onlyOwner
    {
        require(isEpochInProgress, "Epoch not in progress");
        uint256 sharesAsset1 = fundamentalVault1.shares(address(this));
        uint256 sharesAsset2 = fundamentalVault2.shares(address(this));

        fundamentalVault1.initiateWithdraw(sharesAsset1);
        fundamentalVault2.initiateWithdraw(sharesAsset2);
    }

    // *********
    // EPOCH END
    // *********

    /// @notice Complete the withdraw from fundamental vaults
    //it doesn't work, see prev. function
    function withdrawFromFundamentalVaults() external onlyOwner {
        fundamentalVault1.completeWithdraw();
        fundamentalVault2.completeWithdraw();

        isEpochInProgress = false;
    }

    // ****************
    // SETTER FUNCTIONS
    // ****************

    /// @notice function to set the numebr of users to interate when assigning shares
    /// @param _size The iterator count
    function setShareAssignUserSize(uint256 _size) external onlyOwner {
        shareAssignUserSize = _size;
    }

    /// @notice function to set pps
    /// @param _pps New value of pps
    function setPPS(uint256 _pps) external onlyOwner {
        pps = _pps;
    }

    /// @notice function to set total number of shares
    /// @param _n_T new total number of shares
    function set_n_T(uint256 _n_T) external onlyOwner {
        n_T = _n_T;
    }
}

pragma solidity =0.8.14;

import "./OptionsVault.sol";

contract PerformanceFee is OptionsVault {
    /// @notice Function to calcuate performance fee for the epoch
    /// @param E_O The balance of asset1 in the vault at the start of the epoch immediately before the option mint
    /// @param E_v Amount of asset 1 after expiry, before withdrawal and deposit
    /// @param U_O The balance of asset2 in the vault at the start of the epoch immediately before the option mint
    /// @param U_v Amount of asset 2 after expiry, before withdrawal and deposit
    /// @return asset1PerformanceFee Amount of asset 1 to be charged ( can be +ve or -ve )
    /// @return asset2PerformanceFee Amount of asset 2 to be charged ( can be +ve or -ve )
    function calculatePerformanceFee(
        uint256 E_O,
        uint256 E_v,
        uint256 U_O,
        uint256 U_v
    )
        public
        view
        returns (int256 asset1PerformanceFee, int256 asset2PerformanceFee)
    {
        require(!isEpochInProgress, "round is ongoing");

        int256 price = int256(getSpotPrice()); // Assume Price in term of asset2/asset1

        if (E_O < E_v && U_O < U_v) {
            asset1PerformanceFee = (int256(E_v) - int256(E_O)) / 10; // calculated fee in asset1
            asset2PerformanceFee = (int256(U_v) - int256(U_O)) / 10; // calculated fee in asset2
        } else if (E_O >= E_v && U_O >= U_v) {} else {
            int256 deltaEInU = Compute.scaleDecimals(
                (int256(E_v) - int256(E_O)) * price,
                decimalsOfAsset1 + oracleDecimals,
                decimalsOfAsset2
            );

            int256 deltaU = int256(U_v) - int256(U_O);

            if (deltaEInU + deltaU > 0) {
                if (deltaEInU > deltaU) {
                    int256 invPrice = inversePrice(price); // Price in term of asset2/asset1
                    asset1PerformanceFee =
                        (int256(E_v) -
                            int256(E_O) +
                            Compute.scaleDecimals(
                                deltaU * invPrice,
                                decimalsOfAsset2 + oracleDecimals,
                                decimalsOfAsset1
                            )) /
                        10; // calculated in fee assert1
                } else {
                    asset2PerformanceFee = (deltaEInU + deltaU) / 10; // calculated fee in  asset2
                }
            }
        }
    }

    /// @notice function to transfer asset fees to destination addresses
    /// @param _asset1Fee The fees to be deducted from asset 1, can be +ve or 0
    /// @param _asset2Fee The fees to be deducted from asset 2, can be +ve or 0
    function chargePerfomanceFee(
        uint256 _asset1Fee,
        uint256 _asset2Fee,
        address targetAsset
    ) external onlyOwner {
        totalAmountOfAsset1 = totalAmountOfAsset1 - _asset1Fee;
        totalAmountOfAsset2 = totalAmountOfAsset1 - _asset2Fee;
        IERC20(asset1).transfer(targetAsset, _asset1Fee);
        IERC20(asset2).transfer(targetAsset, _asset2Fee);
    }

    function inversePrice(int256 _price) private view returns (int256) {
        return (int256(10**(oracleDecimals << 1)) / _price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../../interfaces/ITrufinThetaVault.sol";
import "../../../interfaces/IMasterWhitelist.sol";

contract Storage is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    struct User {
        uint256 amountOfAsset1;
        uint256 amountOfAsset2;
        uint256 numberOfShares;
        uint256 numberOfSharesOfFundamentalVault1;
        uint256 numberOfSharesOfFundamentalVault2;
        uint256 queuedAmountOfAsset1ToWithdraw;
        uint256 queuedAmountOfAsset2ToWithdraw;
        uint256 roundWhenQueuedWithdrawalWasRequested;
        uint256 amountOfAsset1BeforeCurrentRoundStarted;
        uint256 amountOfAsset2BeforeCurrentRoundStarted;
        address user;
        uint256 reservedValue1;
        uint256 reservedValue2;
        uint256 reservedValue3;
        uint256 reservedValue4;
        uint256 reservedValue5;
    }

    uint256 public maxCapOfAsset1;
    uint256 public minDepositOfAsset1;
    uint256 public totalAmountOfAsset1;
    uint256 public maxCapOfAsset2;
    uint256 public minDepositOfAsset2;
    uint256 public totalAmountOfAsset2;
    uint256 public currentRound;

    uint256 S_E;
    uint256 S_U;

    uint256 e_V; // Amount of usdc without current deposit, i.e. what was left in the vault from the previous vault
    uint256 u_V; // Amount of usdc without current deposit, i.e. what was left in the vault from the previous vault
    uint256 n_T = 10**18; // Amount of shares in the vault that have remained from the previous epoch.

    ITrufinThetaVault public fundamentalVault1;
    ITrufinThetaVault public fundamentalVault2;
    address public asset1;
    address public asset2;
    uint8 internal decimalsOfAsset1;
    uint8 internal decimalsOfAsset2;
    IMasterWhitelist public whiteList;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
pragma solidity =0.8.14;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Vault} from "./Vault.sol";

library ShareMath {
    using SafeMath for uint256;

    uint256 internal constant PLACEHOLDER_UINT = 1;

    /**
     * @dev return the amount of shares for given asset amount
     * @param assetAmount the asset amount
     * @param assetPerShare how much asset is need for share
     * @param decimals the asset decimals
     * @return the amount of shares for given asset amount
     */
    function assetToShares(
        uint256 assetAmount,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return assetAmount.mul(10**decimals).div(assetPerShare);
    }

    /**
     * @dev return the asset amount for given number of shares
     * @param shares the number of shares
     * @param assetPerShare how much asset is need for share
     * @param decimals the asset decimals
     * @return the asset amount for given shares
     */
    function sharesToAsset(
        uint256 shares,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return shares.mul(assetPerShare).div(10**decimals);
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param assetPerShare is the price in asset per share
     * @param decimals is the number of decimals the asset/shares use
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        Vault.DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound = assetToShares(
                depositReceipt.amount,
                assetPerShare,
                decimals
            );

            return
                uint256(depositReceipt.unredeemedShares).add(sharesFromRound);
        }
        return depositReceipt.unredeemedShares;
    }

    /**
     * @dev return the price of unit of share denominated in the asset
     * @param totalSupply total supply of shares
     * @param totalBalance the total amount of asset (including pending ammount)
     * @param pendingAmount the amount of asset that is pending until next round
     * (currently not actively managed by the vault)
     * @param decimals the shares decimals
     * @return the price for single share
     */
    function pricePerShare(
        uint256 totalSupply,
        uint256 totalBalance,
        uint256 pendingAmount,
        uint256 decimals
    ) internal pure returns (uint256) {
        uint256 singleShare = 10**decimals;
        return
            totalSupply > 0
                ? singleShare.mul(totalBalance.sub(pendingAmount)).div(
                    totalSupply
                )
                : singleShare;
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    /**
     * @dev require that the given number is within uint104 range
     */
    function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    /**
     * @dev require that the given number is within the uint128 range
     */
    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @dev Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    /// @dev Premium discount has 1-decimal place. For example: 80 * 10**1 = 80%. Which represents a 20% discount.
    uint256 internal constant PREMIUM_DISCOUNT_MULTIPLIER = 10;

    /// @dev Otokens have 8 decimal places.
    uint256 internal constant OTOKEN_DECIMALS = 8;

    /// @dev Percentage of funds allocated to options is 2 decimal places. 10 * 10**2 = 10%
    uint256 internal constant OPTION_ALLOCATION_MULTIPLIER = 10**2;

    /// @dev Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    /// @dev struct for vault general data
    struct VaultParams {
        /// @dev Option type the vault is selling
        bool isPut;
        /// @dev Token decimals for vault shares
        uint8 decimals;
        /// @dev Asset used in Theta Vault
        address asset;
        /// @dev Underlying asset of the options sold by vault
        address underlying;
        /// @dev Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        /// @dev Vault cap
        uint104 cap;
    }

    /// @dev struct for vault state of the options sold and the timelocked option
    struct OptionState {
        /// @dev Option that the vault is shorting / longing in the next cycle
        address nextOption;
        /// @dev Option that the vault is currently shorting / longing
        address currentOption;
        /// @dev The timestamp when the `nextOption` can be used by the vault
        uint32 nextOptionReadyAt;
    }

    /// @dev struct for vault accounting state
    struct VaultState {
        /**
         * @dev 32 byte slot 1
         * Current round number. `round` represents the number of `period`s elapsed.
         */
        uint16 round;
        /// @dev Amount that is currently locked for selling options
        uint104 lockedAmount;
        /**
         * @dev Amount that was locked for selling options in the previous round
         * used for calculating performance fee deduction
         */
        uint104 lastLockedAmount;
        /**
         * @dev 32 byte slot 2
         * Stores the total tally of how much of `asset` there is
         * to be used to mint rTHETA tokens
         */
        uint128 totalPending;
        /// @dev Amount locked for scheduled withdrawals;
        uint128 queuedWithdrawShares;
    }

    /// @dev struct for pending deposit for the round
    struct DepositReceipt {
        /// @dev Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        /// @dev Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        /// @dev Unredeemed shares balance
        uint128 unredeemedShares;
    }

    /// @dev struct for pending withdrawals
    struct Withdrawal {
        /// @dev Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        /// @dev Number of shares withdrawn
        uint128 shares;
    }

    /// @dev struct for auction sell order
    struct AuctionSellOrder {
        /// @dev Amount of `asset` token offered in auction
        uint96 sellAmount;
        /// @dev Amount of oToken requested in auction
        uint96 buyAmount;
        /// @dev User Id of delta vault in latest gnosis auction
        uint64 userId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    /// Returns the decimal precision of the ERC20 token
    function decimals() external view returns (uint8);

    /// Returns the symbol of the ERC20 token
    function symbol() external view returns (string calldata);

    /// Returns the name of the ERC20 token
    function name() external view returns (string calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface IWMATIC {
    /**
     * @notice wrap deposited MATIC into WMATIC
     */
    function deposit() external payable;

    /**
     * @notice withdraw MATIC from contract
     * @dev Unwrap from WMATIC to MATIC
     * @param wad amount WMATIC to unwrap and withdraw
     */
    function withdraw(uint256 wad) external;

    /**
     * @notice Returns the WMATIC balance of @param account
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice transfer WMATIC
     * @param dst destination address
     * @param wad amount to transfer
     * @return True if tx succeeds, False if not
     */
    function transfer(address dst, uint256 wad) external returns (bool);

    /**
     * @notice Returns amount spender is allowed to spend on behalf of the owner
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @notice approve transfer
     * @param guy address to approve
     * @param wad amount of WMATIC
     * @return True if tx succeeds, False if not
     */
    function approve(address guy, uint256 wad) external returns (bool);

    /**
     * @notice transfer from address
     * @param src source address
     * @param dst destination address
     * @param wad amount to transfer
     * @return True if tx succeeds, False if not
     */
    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {Vault} from "../libraries/Vault.sol";

interface ITrufinThetaVault {
    // Getter function of Vault.OptionState.currentOption
    // Option that the vault is currently shorting / longing
    function currentOption() external view returns (address);

    // Getter function of Vault.OptionState.nextOption
    // Option that the vault is shorting / longing in the next cycle
    function nextOption() external view returns (address);

    // Getter function of struct Vault.VaultParams
    function vaultParams() external view returns (Vault.VaultParams memory);

    // Getter function of struct Vault.VaultState
    function vaultState() external view returns (Vault.VaultState memory);

    // Getter function of struct Vault.OptionParams
    function optionState() external view returns (Vault.OptionState memory);

    // Returns the Gnosis AuctionId of this vault option
    function optionAuctionID() external view returns (uint256);

    function withdrawInstantly(uint256 amount) external;

    function completeWithdraw() external;

    function initiateWithdraw(uint256 numShares) external;

    function shares(address account) external view returns (uint256);

    function deposit(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./BaseDoubleLinkedList.sol";
import "../storage/Storage.sol";

/// @title UserDoubleLinkedList
/// @notice It extends to the User struct the base functionality of a mapped list BaseDoubleLinkedList with O(1)
/// @notice complexity for insert, delete, get and check if it exists
contract UserDoubleLinkedList is BaseDoubleLinkedList, Storage {
    uint256 private constant ZERO = 0;
    /// @dev mapping to store users, the key is user address
    mapping(address => User) internal users;

    //https://docs.openzeppelin.com/contracts/3.x/upgradeable#storage_gaps
    uint256[50] private __gap;

    /// @dev when a user is removed, this event will be emit
    /// @param _user - address of removed user
    event UserRemoved(address indexed _user);

    /// @dev it is a wrapper of User structure
    /// @param _address - address of user
    /// @return User structure or zeroed User structure if _address isn't in the list
    function _processGetUserResult(address _address)
        private
        view
        returns (User memory)
    {
        if ((_address == ZERO_ADDRESS) || !exists(_address)) {
            return (
                User(
                    ZERO,
                    ZERO,
                    ZERO,
                    ZERO,
                    ZERO,
                    ZERO,
                    ZERO,
                    ZERO,
                    ZERO,
                    ZERO,
                    ZERO_ADDRESS,
                    ZERO,
                    ZERO,
                    ZERO,
                    ZERO,
                    ZERO
                )
            );
        }
        return (users[_address]);
    }

    /// @dev add a user to the list
    /// @param _user - User structure
    function putUser(User memory _user) internal {
        require(_user.user != ZERO_ADDRESS, "ZERO user is not allowed");
        //put address into BaseDoubleLinkedList
        _put(_user.user);
        //put User structure into internal mapping
        users[_user.user] = _user;
    }

    /// @dev remove a user from the list
    /// @param _user - user's address
    /// @return true if the user was removed else false
    function removeUser(address _user) internal returns (bool) {
        bool result = exists(_user) && _remove(_user);
        if (result) {
            //if the user was removed - remove according item of internal users mapping
            delete users[_user];
            emit UserRemoved(_user);
        }
        return (result);
    }

    /// @notice gets User structure
    /// @param _user - user's address
    /// @return User structure or zeroed User structure if _user isn't in the list
    function getUser(address _user) public view returns (User memory) {
        return (_processGetUserResult(_user));
    }

    /// @dev gets the first user in the list. Internal iterator will be used
    /// @return User structure of the first user or zeroed User structure if the list is empty
    function getFirstUser() internal returns (User memory) {
        return (_processGetUserResult(iterate_first()));
    }

    /// @dev gets the next user in the list. Internal iterator is used
    /// @return User structure of the next user or zeroed User structure if the iterator has achieved the end of the
    /// list
    function getNextUser() internal returns (User memory) {
        return (_processGetUserResult(iterate_next()));
    }

    /// @dev gets the first user in the list. Internal iterator will NOT be used
    /// @return User structure of the first user or zeroed User structure if the list is empty
    function getFirstUserView() internal view returns (User memory) {
        return (_processGetUserResult(getFirst()));
    }

    /// @dev get the next user in the list. Internal iterator is NOT used
    /// @param _user - address of an item, which is predecessor of the next user
    /// @return User structure of the next user or zeroed User structure if _user points to the last item or _user
    /// doesn't exists

    function getNextUserView(address _user)
        internal
        view
        returns (User memory)
    {
        return (_processGetUserResult(getNext(_user)));
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../helpers/MasterWhitelist.sol";

/**
 * @title Master Whitelist Interface
 * @notice Interface for contract that manages the whitelists for: Lawyers, Market Makers, Users, Vaults, and Assets
 */
interface IMasterWhitelist {
    /**
     * @notice Checks if a Market Maker is in the Whitelist
     * @param _mm is the Market Maker address
     */
    function isMMWhitelisted(address _mm) external view returns (bool);

    /**
     * @notice Checks if a Vault is in the Whitelist
     * @param _vault is the Vault address
     */
    function isVaultWhitelisted(address _vault) external view returns (bool);

    /**
     * @notice Checks if a User is in the Whitelist
     * @param _user is the User address
     */
    function isUserWhitelisted(address _user) external view returns (bool);

    /**
     * @notice Checks if an Asset is in the Whitelist
     * @param _asset is the Asset address
     */
    function isAssetWhitelisted(address _asset) external view returns (bool);

    /**
     * @notice Returns id of a market maker address
     * @param _mm is the market maker address
     */
    function getIdMM(address _mm) external view returns (uint256);

    /**
     * @notice Checks if a user is whitelisted for the Gnosis auction, returns "0x19a05a7e" if it is
     * @param _user is the User address
     * @param _auctionId is not needed for now
     * @param _callData is not needed for now
     */
    function isAllowed(
        address _user,
        uint256 _auctionId,
        bytes calldata _callData
    ) external view returns (bytes4);
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

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMasterWhitelist.sol";

/**
 * @title Master Whitelist
 * @notice Contract that manages the whitelists for: Lawyers, Market Makers, Users, Vaults, and Assets
 */
contract MasterWhitelist is Ownable, IMasterWhitelist {
    /**
     * @notice Whitelist for lawyers, who are in charge of managing the other whitelists
     */
    mapping(address => bool) lawyers;

    /**
     * @notice Whitelist for Market Makers
     */
    mapping(address => bool) whitelistedMMs;

    /**
     * @notice maps Market Maker addresses to the id of the MM they belong to
     */
    mapping(address => uint256) idMM;

    /**
     * @notice Whitelist for Users
     */
    mapping(address => bool) whitelistedUsers;

    /**
     * @notice Whitelist for Vaults
     */
    mapping(address => bool) whitelistedVaults;

    /**
     * @notice Whitelist for Assets
     */
    mapping(address => bool) whitelistedAssets;

    /**
     * @notice swap manager is in charge of initiating swaps
     */
    address public swapManager;

    /**
     * @notice emits an event when an address is added to a whitelist
     * @param user is the address added to whitelist
     * @param userType can take values 0,1,2 if the address is a user, market maker or vault respectively
     */
    event userAddedToWhitelist(address indexed user, uint256 indexed userType);

    /**
     * @notice emits an event when an address is removed from the whitelist
     * @param user is the address removed from the whitelist
     * @param userType can take values 0,1,2 if the address is a user, market maker or vault respectively
     */
    event userRemovedFromWhitelist(
        address indexed user,
        uint256 indexed userType
    );

    /**
     * @notice Requires that the transaction sender is a lawyer
     */
    modifier onlyLawyer() {
        require(lawyers[msg.sender], "Lawyer: caller is not a lawyer");
        _;
    }

    /**
     * @notice set swap manager
     * @param _sm is the swap manager address
     */
    function setSwapManager(address _sm) external onlyOwner {
        swapManager = _sm;
    }

    /**
     * @notice get swap manager
     */
    function getSwapManager() external view returns (address) {
        return swapManager;
    }

    /**
     * @notice adds a lawyer to the lawyer whitelist
     * @param _lawyer is the lawyer address
     */
    function addLawyer(address _lawyer) external onlyOwner {
        lawyers[_lawyer] = true;
    }

    /**
     * @notice removes a lawyer from the lawyer whitelist
     * @param _lawyer is the lawyer address
     */
    function removeLawyer(address _lawyer) external onlyOwner {
        lawyers[_lawyer] = false;
    }

    /**
     * @notice verifies that the lawyer is whitelisted
     * @param _lawyer is the lawyer address
     */
    function isLawyer(address _lawyer) external view returns (bool) {
        return lawyers[_lawyer];
    }

    /**
     * @notice Adds a User to the Whitelist
     * @param _user is the User address
     */
    function addUserToWhitelist(address _user) external onlyLawyer {
        whitelistedUsers[_user] = true;
        emit userAddedToWhitelist(_user, 0);
    }

    /**
     * @notice Removes a User from the Whitelist
     * @param _user is the User address
     */
    function removeUserFromWhitelist(address _user) external onlyLawyer {
        whitelistedUsers[_user] = false;
        emit userRemovedFromWhitelist(_user, 0);
    }

    /**
     * @notice Checks if a User is in the Whitelist
     * @param _user is the User address
     */
    function isUserWhitelisted(address _user) external view returns (bool) {
        return whitelistedUsers[_user];
    }

    /**
     * @notice Adds a Market Maker to the Whitelist
     * @param _mm is the Market Maker address
     */
    function addMMToWhitelist(address _mm) external onlyLawyer {
        whitelistedMMs[_mm] = true;
        emit userAddedToWhitelist(_mm, 1);
    }

    /**
     * @notice Removes a Market Maker from the Whitelist
     * @param _mm is the Market Maker address
     */
    function removeMMFromWhitelist(address _mm) external onlyLawyer {
        whitelistedMMs[_mm] = false;
        emit userRemovedFromWhitelist(_mm, 1);
    }

    /**
     * @notice Checks if a Market Maker is in the Whitelist
     * @param _mm is the Market Maker address
     */
    function isMMWhitelisted(address _mm) external view returns (bool) {
        return whitelistedMMs[_mm];
    }

    /**
     * @notice Adds a Vault to the Whitelist
     * @param _vault is the Vault address
     */
    function addVaultToWhitelist(address _vault) external onlyLawyer {
        whitelistedVaults[_vault] = true;
        emit userAddedToWhitelist(_vault, 2);
    }

    /**
     * @notice Removes a Vault from the Whitelist
     * @param _vault is the Vault address
     */
    function removeVaultFromWhitelist(address _vault) external onlyLawyer {
        whitelistedMMs[_vault] = false;
        emit userRemovedFromWhitelist(_vault, 2);
    }

    /**
     * @notice Checks if a Vault is in the Whitelist
     * @param _vault is the Vault address
     */
    function isVaultWhitelisted(address _vault) external view returns (bool) {
        return whitelistedVaults[_vault];
    }

    /**
     * @notice Adds an Asset to the Whitelist
     * @param _asset is the Asset address
     */
    function addAssetToWhitelist(address _asset) external onlyLawyer {
        whitelistedAssets[_asset] = true;
    }

    /**
     * @notice Removes an Asset from the Whitelist
     * @param _asset is the Asset address
     */
    function removeAssetFromWhitelist(address _asset) external onlyLawyer {
        whitelistedAssets[_asset] = false;
    }

    /**
     * @notice Checks if an Asset is in the Whitelist
     * @param _asset is the Asset address
     */
    function isAssetWhitelisted(address _asset) external view returns (bool) {
        return whitelistedAssets[_asset];
    }

    /**
     * @notice Adds an id to a Market Maker address to identify a Market Maker by its address
     * @param _mm is the mm address
     * @param _id is the unique identifier of the market maker
     */
    function setIdMM(address _mm, uint256 _id) external onlyLawyer {
        idMM[_mm] = _id;
    }

    /**
     * @notice Returns id of a market maker address
     * @param _mm is the market maker address
     */
    function getIdMM(address _mm) external view returns (uint256) {
        return idMM[_mm];
    }

    /**
     * @notice Checks if a user is whitelisted for the Gnosis auction, returns "0x19a05a7e" if it is
     * @param _user is the User address
     * @param _auctionId is not needed for now
     * @param _callData is not needed for now
     */
    function isAllowed(
        address _user,
        uint256 _auctionId,
        bytes calldata _callData
    ) external view returns (bytes4) {
        if (whitelistedMMs[_user]) {
            return 0x19a05a7e;
        } else {
            return bytes4(0);
        }
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
pragma solidity 0.8.14;

/// @title BaseDoubleLinkedList
/// @notice It realises the base functionality of a mapped list with O(1) complexity for insert, delete, get and check
/// @notice if it exists.
/// @dev This contract should be inherited and an additional contract should be developed to implement a certaint
/// @dev Structure to save in the DoubleLinkedList (see, for instance, UserDoubleLinkedList.sol)

contract BaseDoubleLinkedList {
    /// @dev pointer on the next item
    mapping(address => address) private next;
    /// @dev pointer on the previous item
    mapping(address => address) private prev;
    /// @dev items count. In some cases, for complicated structures, size can not be equal to item count, so size can
    /// @dev be redefined (as function) in a child contract. But for most cases size = items count
    uint256 internal size;
    address internal constant ZERO_ADDRESS = address(0);
    /// @dev uses as prev for the first item
    address private constant HEAD = address(1);
    /// @dev pointer to the last item
    address private last;
    /// @dev uses for iteration through list in iterateFirst/iterateNext functions
    address private iterator;
    /// @dev max iteration limit for one call of clear_start\clear_next. It can happen if the list is huge and clear
    /// @dev all items for one call will be impossible because of the block gas limit. So, this variable regulates
    /// @dev iteration limit for a single call. The value depends on use-cases and can be set to different numbers for
    /// @dev different project (gas consumption of clear_start\clear_next is stable, but it is unknown gas-consumption
    /// @dev of a caller, so this value should be picked up individually for each project)

    uint256 private iterationCountLimit;

    //https://docs.openzeppelin.com/contracts/3.x/upgradeable#storage_gaps
    uint256[50] private __gap;

    /// @dev list doesn't accept reserved values (ZERO_ADDRESS and HEAD)
    /// @param _address - address to check
    modifier shouldntUseReservedValues(address _address) {
        require(_address > HEAD, "don't use reserved values");
        _;
    }

    /// @dev init the last element and point it to Head
    /// @param _iterationCountLimit - max iteration limit for one call of clear_start\clear_next
    function init(uint256 _iterationCountLimit) internal {
        last = HEAD;
        iterationCountLimit = _iterationCountLimit;
    }

    /// @dev add an item to the list with complexity O(1)
    /// @param _address - item
    /// @return true if an item was added, false otherwise
    function _put(address _address)
        internal
        shouldntUseReservedValues(_address)
        returns (bool)
    {
        //new item always has prev[_address] equal ZERO_ADDRESS
        if (prev[_address] == ZERO_ADDRESS) {
            //set the next element to _address for the current last element
            next[last] = _address;
            //set prev element of _address to the current last element
            prev[_address] = last;
            //set last to _address
            last = _address;
            ++size;
            return true;
        }
        return false;
    }

    /// @dev remove an item from the list with complexity of O(1).
    /// @param _address - item to delete
    /// @return true if the item was deleted, false otherwise
    function _remove(address _address)
        internal
        shouldntUseReservedValues(_address)
        returns (bool)
    {
        //existing item has prev[_address] non equal ZERO_ADDRESS.
        if (prev[_address] != ZERO_ADDRESS) {
            address prevAddress = prev[_address];
            address nextAddress = next[_address];
            delete next[_address];
            //set next of prevAddress to next of _address
            next[prevAddress] = nextAddress;
            //if iterateFirst\iterateNext iterator equal _address, it means that it pointed to the deleted item,
            //So, the iterator should be reset to the next item
            if (iterator == _address) {
                iterator = nextAddress;
            }
            //if removed the last (by order, not by size) item
            if (nextAddress == ZERO_ADDRESS) {
                //set the pointer of the last item to prevAddress
                last = prevAddress;
            } else {
                //else prev item of next address sets to prev address of deleted item
                prev[nextAddress] = prevAddress;
            }

            delete prev[_address];
            --size;
            return true;
        }
        return false;
    }

    /// @dev check if _address is in the list
    /// @param _address - address to check
    /// @return true if _address is in the list, false otherwise
    function exists(address _address) internal view returns (bool) {
        //items in the list have prev which points to non ZERO_ADDRESS
        return prev[_address] != ZERO_ADDRESS;
    }

    /// @dev starts iterating through the list. The iterator will be saved inside contract
    /// @return address of first item or ZERO_ADDRESS if the list is empty
    function iterate_first() internal returns (address) {
        iterator = next[HEAD];
        return iterator;
    }

    /// @dev gets the next item which is pointed by the iterator
    /// @return next item or ZERO_ADDRESS if the iterator is pointed to the last item
    function iterate_next() internal returns (address) {
        //if the iterator is ZERO_ADDRES, it means that the list is empty or the iteration process is finished
        if (iterator == ZERO_ADDRESS) {
            return ZERO_ADDRESS;
        }
        iterator = next[iterator];
        return iterator;
    }

    /// @dev remove min(size, iterationCountLimit) of items
    /// @param _iterator - address, which is a start point of removing
    /// @return address of the item, which can be passed to _clear to continue removing items. If all items removed,
    /// ZERO_ADDRESS will be returned
    function _clear(address _iterator) private returns (address) {
        uint256 i = 0;
        while ((_iterator != ZERO_ADDRESS) && (i < iterationCountLimit)) {
            address nextIterator = next[_iterator];
            _remove(_iterator);
            _iterator = nextIterator;
            unchecked {
                i = i + 1;
            }
        }
        return _iterator;
    }

    /// @dev starts removing all items
    /// @return next item to pass into clear_next, if list's size > iterationCountLimit, ZERO_ADDRESS otherwise
    function clear_init() internal returns (address) {
        return (_clear(next[HEAD]));
    }

    /// @dev continues to remove all items
    /// @param _startFrom - address which is a start point of removing
    /// @return next item to pass into clear_next, if current list's size > iterationCountLimit, ZERO_ADDRESS otherwise
    function clear_next(address _startFrom) internal returns (address) {
        return (_clear(_startFrom));
    }

    /// @dev get the first item of the list
    /// @return first item of the list or ZERO_ADDRESS if the list is empty
    function getFirst() internal view returns (address) {
        return (next[HEAD]);
    }

    /// @dev gets the next item following _prev
    /// @param _prev - current item
    /// @return the next item following _prev
    function getNext(address _prev) internal view returns (address) {
        return (next[_prev]);
    }
}

pragma solidity ^0.8.14;
import "hardhat/console.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";

import "./WadRay.sol";

library Compute {
    using WadRayMath for uint256;

    function mulPrice(
        uint256 _price1,
        uint8 _decimals1,
        uint256 _price2,
        uint8 _decimals2,
        uint8 _outDecimals
    ) internal pure returns (uint256) {
        uint8 multiplier = 18 - _decimals1;
        uint8 multiplier2 = 18 - _decimals2;
        uint8 outMultiplier = 18 - _outDecimals;

        _price1 *= 10**multiplier;
        _price2 *= 10**multiplier2;

        uint256 output = _price1.wadMul(_price2);

        return output / (10**outMultiplier);
    }

    function divPrice(
        uint256 _numerator,
        uint8 _numeratorDecimals,
        uint256 _denominator,
        uint8 _denominatorDecimals,
        uint8 _outDecimals
    ) internal pure returns (uint256) {
        uint8 multiplier = 18 - _numeratorDecimals;
        uint8 multiplier2 = 18 - _denominatorDecimals;
        uint8 outMultiplier = 18 - _outDecimals;
        _numerator *= 10**multiplier;
        _denominator *= 10**multiplier2;

        uint256 output = _numerator.wadDiv(_denominator);
        return output / (10**outMultiplier);
    }

    function scaleDecimals(
        uint256 value,
        uint8 _oldDecimals,
        uint8 _newDecimals
    ) internal pure returns (uint256) {
        uint8 multiplier;
        if (_oldDecimals > _newDecimals) {
            multiplier = _oldDecimals - _newDecimals;
            return value / (10**multiplier);
        } else {
            multiplier = _newDecimals - _oldDecimals;
            return value * (10**multiplier);
        }
    }

    function scaleDecimals(
        int256 value,
        uint8 _oldDecimals,
        uint8 _newDecimals
    ) internal pure returns (int256) {
        uint8 multiplier;
        if (_oldDecimals > _newDecimals) {
            multiplier = _oldDecimals - _newDecimals;
            return value / int256(10**multiplier);
        } else {
            multiplier = _newDecimals - _oldDecimals;
            return value * int256(10**multiplier);
        }
    }

    function wadDiv(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        return value1.wadDiv(value2);
    }

    function wadMul(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        return value1.wadMul(value2);
    }

    function _scaleAssetAmountTo18(address _asset, uint256 _originalAmount)
        internal
        view
        returns (uint256)
    {
        uint8 decimals = IERC20Detailed(_asset).decimals();
        uint256 scaledAmount;
        if (decimals <= 18) {
            scaledAmount = _originalAmount * (10**(18 - decimals));
        } else {
            scaledAmount = _originalAmount / (10**(decimals - 18));
        }
        return scaledAmount;
    }

    function _unscaleAssetAmountToOriginal(
        address _asset,
        uint256 _scaledAmount
    ) internal view returns (uint256) {
        uint8 decimals = IERC20Detailed(_asset).decimals();
        uint256 unscaledAmount;
        if (decimals <= 18) {
            unscaledAmount = _scaledAmount / (10**(18 - decimals));
        } else {
            unscaledAmount = _scaledAmount * (10**(decimals - 18));
        }
        return unscaledAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library WadRayMath {
    using SafeMath for uint256;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function ray() internal pure returns (uint256) {
        return RAY;
    }

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfWAD.add(a.mul(b)).div(WAD);
    }

    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(WAD)).div(b);
    }

    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfRAY.add(a.mul(b)).div(RAY);
    }

    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(RAY)).div(b);
    }

    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;

        return halfRatio.add(a).div(WAD_RAY_RATIO);
    }

    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a.mul(WAD_RAY_RATIO);
    }

    //solium-disable-next-line
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }
}