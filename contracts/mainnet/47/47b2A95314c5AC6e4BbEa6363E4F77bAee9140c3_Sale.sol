// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import './common/AccessControl.sol';
import './common/Utils.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/**
 * @dev Partial interface of the Rates contract.
 */
interface IRates {
    function getUsdRate (
        address contractAddress
    ) external view returns (uint256);
}

/**
 * @dev Sale contract,
 * functions names are self explanatory
 */
contract Sale is AccessControl, Utils, Initializable {
    using ECDSA for bytes32;

    event Purchase(
        address indexed userAddress,
        address indexed paymentToken,
        address referrer,
        uint256 paidAmount,
        uint256 usdPaidAmount,
        uint256 purchasedAmount
    );

    event Withdraw(
        address indexed userAddress,
        uint256 withdrawAmount
    );

    struct PaymentProfile {
        address contractAddress; // if == zero payments are in the native currency
        uint256 weight; // sorting order at UI (asc from left to right)
        uint256 totalPaid;  // total amount of tokens paid in this currency
        string name;
        string currency;
        bool active;
    }

    struct Round {
        uint256 usdRate; // syntrum token price in USD multiplied by 10 ** 18
        uint256 startTime; // unix timestamp
        uint256 endTime; // unix timestamp
        uint256 duration; // duration in seconds
        uint256 maxAllocation; // maximum allocation of Syntrum tokens
        uint256 allocated; // amount of allocated Syntrum tokens
    }

    struct TokenReleaseStage {
        uint16 percentage; // purchased tokens percentage to be released
        uint256 activationTime;  // stage activation timestamp
    }

    mapping (uint8 => PaymentProfile) internal _paymentProfiles;
    mapping (uint8 => TokenReleaseStage) internal _releaseStages;
    mapping (uint8 => Round) internal _rounds;
    mapping (address => uint256) internal _purchasedAmount;
    mapping (address => uint256) internal _referralAmount;
    mapping (address => uint256) internal _withdrawnAmount;
    mapping(address => uint256) internal _innerRates;
    mapping (address => bool) internal _whitelist;
    
    IRates internal _rates;
    address internal _syntrumTokenAddress;
    address _receiver;
    bytes32 internal constant MANAGER = keccak256(abi.encode('MANAGER'));
    bytes32 internal constant SIGNER = keccak256(abi.encode('SIGNER'));
    bool internal _isPublic;
    uint256 internal _usdTotalPaid; // paid in total in usd (stablecoins)
    uint256 internal _totalWithdrawn; // withdrawn token amount (for statistics)
    uint256 internal _maxPurchaseAmount;
    // Max amount of tokens that can be purchased by address
    uint256 internal _referralFee;
    uint256 internal constant SHIFT_18 = 10 ** 18;
    uint256 internal constant SHIFT_4 = 10 ** 4;
    uint16 internal _batchLimit;
    // limit for array length when added/removed to/from whitelist
    uint8 internal _tokenReleaseStagesNumber;
    // number of the stages of token releasing
    uint8 internal _paymentProfilesNumber; // number of payment profiles
    uint8 internal _roundsNumber; // number of rounds
    uint8 internal _maxRoundsNumber;
    uint8 internal _activeRoundIndex;

    /**
     * @dev constructor
     */
    function initialize (
        address ownerAddress,
        address managerAddress,
        address ratesAddress,
        address syntrumTokenAddress,
        address receiverAddress
    ) public initializer returns (bool) {
        require(ownerAddress != address(0), 'ownerAddress can not be zero');
        require(managerAddress != address(0), 'managerAddress can not be zero');
        require(ratesAddress != address(0), 'ratesAddress can not be zero');
        require(syntrumTokenAddress != address(0), 'syntrumTokenAddress can not be zero');
        require(receiverAddress != address(0), 'receiverAddress can not be zero');
        require(
            syntrumTokenAddress != address(0), 'syntrumTokenAddress can not be zero'
        );
        _owner = ownerAddress;
        _grantRole(MANAGER, managerAddress);
        _rates =  IRates(ratesAddress);
        _syntrumTokenAddress = syntrumTokenAddress;
        _receiver = receiverAddress;
        _maxRoundsNumber = 254;
        _batchLimit = 100;
        _referralFee = 500;
        return true;
    }

    function addToWhitelist (address userAddress) external hasRole(MANAGER) returns (bool) {
        _whitelist[userAddress] = true;
        return true;
    }

    function addToWhitelistMultiple (
        address[] calldata userAddresses
    ) external hasRole(MANAGER) returns (bool) {
        for (uint16 i; i < userAddresses.length; i ++) {
            if (i >= _batchLimit) break;
            _whitelist[userAddresses[i]] = true;
        }
        return true;
    }

    function removeFromWhitelist (address userAddress) external hasRole(MANAGER) returns (bool) {
        _whitelist[userAddress] = false;
        return true;
    }

    function removeFromWhitelistMultiple (
        address[] calldata userAddresses
    ) external hasRole(MANAGER) returns (bool) {
        for (uint16 i; i < userAddresses.length; i ++) {
            if (i >= _batchLimit) break;
            _whitelist[userAddresses[i]] = false;
        }
        return true;
    }

    function isWhitelisted (address userAddress) external view returns (bool) {
        return _whitelist[userAddress];
    }

    function setBatchLimit (
        uint16 batchLimit
    ) external hasRole(MANAGER) returns (bool) {
        require(batchLimit > 0, 'Batch limit should be greater than zero');
        _batchLimit = batchLimit;
        return true;
    }

    function getBatchLimit () external view returns (uint16) {
        return _batchLimit;
    }

    function setReferralFee (
        uint256 referralFee
    ) external hasRole(MANAGER) returns (bool) {
        _referralFee = referralFee;
        return true;
    }

    function getReferralFee () external view returns (uint256) {
        return _referralFee;
    }

    function _checkSale () internal returns (bool) {
        if (
            _activeRoundIndex == 0
                && _rounds[1].startTime < block.timestamp
        ) {
            _activeRoundIndex = 1;
        }
        require(_activeRoundIndex > 0, 'Sale is not started yet');
        if (!(
                _rounds[_activeRoundIndex].allocated
                    < _rounds[_activeRoundIndex].maxAllocation
        ))  {
            require(_activeRoundIndex < _roundsNumber, 'Sale is over');
            _activeRoundIndex ++;
        }
        uint8 activeRoundIndex = _activeRoundIndex;
        for (uint8 i = activeRoundIndex; i <= _roundsNumber; i ++) {
            if (_rounds[i].endTime < block.timestamp) {
                require(i < _roundsNumber, 'Sale is over');
                _activeRoundIndex = i + 1;
                if (_rounds[i].maxAllocation > _rounds[i].allocated) {
                    _rounds[_activeRoundIndex].maxAllocation
                        += (_rounds[i].maxAllocation - _rounds[i].allocated);
                }
            } else {
                break;
            }
        }

        return true;
    }

    function checkPermission (
        bytes memory signature
    ) public view returns (bool) {
        if (_isPublic) return true;
        if (_whitelist[msg.sender]) return true;
        require(signature.length > 0, "Sale is in private mode");
        bytes memory message = abi.encode(msg.sender);
        address signer = keccak256(message)
            .toEthSignedMessageHash()
            .recover(signature);
        require(_checkRole(SIGNER, signer), "Signature is not valid");
        return true;
    }

    function getRatesContract () external view returns (address) {
        return address(_rates);
    }

    function setRatesContract (
        address ratesAddress
    ) external hasRole(MANAGER) returns (bool) {
        require(ratesAddress != address(0), 'ratesAddress can not be zero');
        _rates =  IRates(ratesAddress);
        return true;
    }

    function getReceiver () external view returns (address) {
        return _receiver;
    }

    function setReceiver (
        address receiverAddress
    ) external onlyOwner returns (bool) {
        require(receiverAddress != address(0), 'receiverAddress can not be zero');
        _receiver =  receiverAddress;
        return true;
    }

    function getRate (
        address tokenAddress
    ) public view returns (uint256) {
        if (tokenAddress == _syntrumTokenAddress) {
            return getSyntrumUsdRate(true);
        }
        if (_innerRates[tokenAddress] > 0) {
            return _innerRates[tokenAddress];
        }
        uint256 rate = _rates.getUsdRate(tokenAddress);
        require(rate > 0, 'Rate calculation error');
        return rate;
    }

    function getSyntrumUsdRate (
        bool needUpdate
    ) public view returns (uint256) {
        if (!needUpdate) return _rounds[_activeRoundIndex].usdRate;
        uint8 activeRoundIndex = getActiveRoundIndex();
        return _rounds[activeRoundIndex].usdRate;
    }

    function getActiveRoundIndex () public view returns (uint8) {
        uint8 activeRoundIndex = _activeRoundIndex;
        if (
            activeRoundIndex == 0
                && _rounds[1].startTime < block.timestamp
        ) {
            activeRoundIndex = 1;
        }
        if (activeRoundIndex == 0) return 0;
        for (uint8 i = activeRoundIndex; i <= _roundsNumber; i ++) {
            if (
                _rounds[i].endTime < block.timestamp
                    || !(_rounds[i].allocated < _rounds[i].maxAllocation)
            ) {
                if (i >= _roundsNumber) return _maxRoundsNumber + 1;
                activeRoundIndex = i + 1;
            } else {
                break;
            }
        }
        return activeRoundIndex;
    }

    function isSaleActive () external view returns (bool) {
        uint8 activeRoundIndex = getActiveRoundIndex();
        return activeRoundIndex > 0
            && activeRoundIndex < _maxRoundsNumber;
    }

    function isSaleOver () external view returns (bool) {
        return getActiveRoundIndex() == _maxRoundsNumber;
    }

    function getInnerRate (
        address tokenAddress
    ) external view returns (uint256) {
        return _innerRates[tokenAddress];
    }

    function setInnerRate (
        address tokenAddress,
        uint256 rate
    ) external hasRole(MANAGER) returns (bool) {
        _innerRates[tokenAddress] = rate;
        return true;
    }

    function getPublic () external view returns (bool) {
        return _isPublic;
    }

    function setPublic (
        bool isPublic
    ) external hasRole(MANAGER) returns (bool) {
        _isPublic =  isPublic;
        return true;
    }

    /**
     * @dev Function accepts payments both in native currency and
     * in predefined erc20 tokens
     * Distributed token is accrued to the buyer's address to be withdrawn later
     */
    function purchase (
        uint8 paymentProfileIndex,
        uint256 paymentAmount, // payment amount
        address tokenReceiver,
        address referrer,
        bytes memory signature
    ) external payable returns (bool) {
        _checkSale();
        checkPermission(signature);
        uint256 syntrumUsdRate = getSyntrumUsdRate(false);
        require(
            tokenReceiver != address(0),
                'Receiver address should not be a zero address'
        );
        require(
            _paymentProfiles[paymentProfileIndex].active,
                'Payment profile is not active or does not exist'
        );
        if (_paymentProfiles[paymentProfileIndex].contractAddress != address(0)) {
            require(
                paymentAmount > 0,
                    'paymentAmount for this payment profile should be greater than zero'
            );
            require(
                msg.value == 0, 'msg.value should be zero for this payment profile'
            );
        } else {
            paymentAmount = msg.value;
            require(
                paymentAmount > 0,
                    'Message value for this payment profile should be greater than zero'
            );
        }
        uint256 usdPaymentAmount = getUsdPaymentAmount(
            paymentProfileIndex, paymentAmount
        );
        uint256 purchaseAmount = usdPaymentAmount
            * SHIFT_18 / syntrumUsdRate;
        if (
            purchaseAmount > _rounds[_activeRoundIndex].maxAllocation
                - _rounds[_activeRoundIndex].allocated
                &&
            _activeRoundIndex < _maxRoundsNumber
                &&
            purchaseAmount <= _rounds[_activeRoundIndex].maxAllocation
                - _rounds[_activeRoundIndex].allocated
                + _rounds[_activeRoundIndex + 1].maxAllocation
        ) {
            uint256 currentRoundPurchase = _rounds[_activeRoundIndex].maxAllocation
                - _rounds[_activeRoundIndex].allocated;

            uint256 nextRoundUsdPayment = usdPaymentAmount
                - (currentRoundPurchase * syntrumUsdRate / SHIFT_18);

            _rounds[_activeRoundIndex].allocated
                = _rounds[_activeRoundIndex].maxAllocation;
            _activeRoundIndex ++;
            syntrumUsdRate = getSyntrumUsdRate(false);

            _rounds[_activeRoundIndex].allocated
                = nextRoundUsdPayment * SHIFT_18 / syntrumUsdRate;
            purchaseAmount = currentRoundPurchase
                + _rounds[_activeRoundIndex].allocated;
        } else {
            require(
                purchaseAmount
                    + _rounds[_activeRoundIndex].allocated
                        <= _rounds[_activeRoundIndex].maxAllocation,
                    'Round pool size exceeded'
            );
            _rounds[_activeRoundIndex].allocated += purchaseAmount;
        }

        require(purchaseAmount > 0, 'Purchase amount calculation error');

        require(
            _maxPurchaseAmount == 0
                || (
                        purchaseAmount + _purchasedAmount[tokenReceiver]
                            <= _maxPurchaseAmount
                    ),
                'Max purchase amount exceeded'
        );
        if (
            _paymentProfiles[paymentProfileIndex].contractAddress
                != address(0)
        ) {
            _takeAsset(
                _paymentProfiles[paymentProfileIndex].contractAddress,
                msg.sender,
                paymentAmount
            );
        }
        _sendAsset(
            _paymentProfiles[paymentProfileIndex].contractAddress,
            _receiver,
            paymentAmount
        );
        _purchasedAmount[tokenReceiver] += purchaseAmount;
        _referralAmount[referrer] += purchaseAmount * _referralFee / SHIFT_4;
        _usdTotalPaid += usdPaymentAmount;
        _paymentProfiles[paymentProfileIndex].totalPaid += paymentAmount;
        emit Purchase(
            msg.sender,
            _paymentProfiles[paymentProfileIndex].contractAddress,
            referrer,
            paymentAmount,
            usdPaymentAmount,
            purchaseAmount
        );
        return true;
    }

    function getUsdPaymentAmount (
        uint8 paymentProfileIndex,
        uint256 paymentAmount
    ) public view returns (uint256) {
        uint256 usdPaymentRate = getRate(
            _paymentProfiles[paymentProfileIndex].contractAddress
        );
        return paymentAmount * usdPaymentRate /  SHIFT_18;
    }

    function getPaymentAmount (
        uint8 paymentProfileIndex,
        uint256 purchaseAmount
    ) external view returns (uint256) {
        uint256 usdPaymentRate = getRate(
            _paymentProfiles[paymentProfileIndex].contractAddress
        );
        uint256 syntrumUsdRate = getSyntrumUsdRate(true);
        if (usdPaymentRate == 0) return 0;
        return purchaseAmount * syntrumUsdRate / usdPaymentRate;
    }

    function getPurchaseAmount (
        uint8 paymentProfileIndex,
        uint256 paymentAmount
    ) external view returns (uint256) {
        uint256 usdPaymentRate = getRate(
            _paymentProfiles[paymentProfileIndex].contractAddress
        );
        uint256 syntrumUsdRate = getSyntrumUsdRate(true);
        if (syntrumUsdRate == 0) return 0;
        return paymentAmount * usdPaymentRate / syntrumUsdRate;
    }

    /**
     * @dev Internal function for purchased token withdraw
     */
    function _withdraw (
        address userAddress,
        uint256 withdrawAmount
    ) internal returns (bool) {
        _withdrawnAmount[userAddress] += withdrawAmount;
        _totalWithdrawn += withdrawAmount;
        emit Withdraw(userAddress, withdrawAmount);
        _sendAsset(_syntrumTokenAddress, userAddress, withdrawAmount);
        return true;
    }

    /**
     * @dev Function let users withdraw specified amount of distributed token
     * (amount that was paid for) when withdrawal is available
     */
    function withdraw (
        uint256 withdrawAmount
    ) external returns (bool) {
        require(
            withdrawAmount > 0,
            'withdrawAmount should be greater than zero'
        );
        require(
            withdrawAmount <= getUserAvailable(msg.sender),
            'withdrawAmount can not be greater than available token amount'
        );
        return _withdraw(msg.sender, withdrawAmount);
    }

    /**
     * @dev Function let users withdraw available purchased tokens
     */
    function withdrawAvailable () external returns (bool) {
        uint256 withdrawAmount = getUserAvailable(msg.sender);
        require(
            withdrawAmount > 0,
            'No tokens available for withdraw'
        );
        return _withdraw(msg.sender, withdrawAmount);
    }

    // manager functions
    function addPaymentProfile (
        address contractAddress,
        uint256 usdPaymentRate,
        uint256 weight,
        string memory name,
        string memory currency
    ) external hasRole(MANAGER) returns (bool) {
        if (usdPaymentRate == 0) {
            require(
                _rates.getUsdRate(contractAddress) > 0,
                    'Token rate can not be zero'
            );
        } else {
            _innerRates[contractAddress] = usdPaymentRate;
        }
        _paymentProfilesNumber ++;
        _paymentProfiles[_paymentProfilesNumber].contractAddress = contractAddress;
        _paymentProfiles[_paymentProfilesNumber].weight = weight;
        _paymentProfiles[_paymentProfilesNumber].name = name;
        _paymentProfiles[_paymentProfilesNumber].currency = currency;
        _paymentProfiles[_paymentProfilesNumber].active = true;
        return true;
    }

    function setPaymentProfileWeight (
        uint8 paymentProfileIndex,
        uint256 weight
    ) external hasRole(MANAGER) returns (bool) {
        require(
            paymentProfileIndex > 0 && paymentProfileIndex <= _paymentProfilesNumber,
            'Payment profile is not found'
        );
        _paymentProfiles[paymentProfileIndex].weight = weight;
        return true;
    }

    function setPaymentProfileName (
        uint8 paymentProfileIndex,
        string calldata name
    ) external hasRole(MANAGER) returns (bool) {
        require(
            paymentProfileIndex > 0 && paymentProfileIndex <= _paymentProfilesNumber,
            'Payment profile is not found'
        );
        _paymentProfiles[paymentProfileIndex].name = name;
        return true;
    }

    function setPaymentProfileCurrency (
        uint8 paymentProfileIndex,
        string calldata currency
    ) external hasRole(MANAGER) returns (bool) {
        require(
            paymentProfileIndex > 0 && paymentProfileIndex <= _paymentProfilesNumber,
            'Payment profile is not found'
        );
        _paymentProfiles[paymentProfileIndex].currency = currency;
        return true;
    }

    function setPaymentProfileStatus (
        uint8 paymentProfileIndex,
        bool active
    ) external hasRole(MANAGER) returns (bool) {
        require(
            paymentProfileIndex > 0 && paymentProfileIndex <= _paymentProfilesNumber,
            'Payment profile is not found'
        );
        _paymentProfiles[paymentProfileIndex].active = active;
        return true;
    }

    function setMaxPurchaseAmount (
        uint256 maxPurchaseAmount
    ) external hasRole(MANAGER) returns (bool) {
        _maxPurchaseAmount = maxPurchaseAmount;
        return true;
    }

    function setTokenReleaseStageData (
        uint256[] calldata timestamps, uint16[] calldata percentage
    ) external hasRole(MANAGER) returns (bool) {
        require(
            timestamps.length == percentage.length,
            'Arrays should be of the same length'
        );
        uint8 stagesNumber;
        uint256 previousTimestamp;
        for (uint256 i = 0; i < timestamps.length; i ++) {
            require(
                timestamps[i] > previousTimestamp,
                'Each timestamp should be greater than previous one'
            );
            require(
                percentage[i] <= SHIFT_4,
                'Percentage should not be greater than 10000'
            );
            previousTimestamp = timestamps[i];
            stagesNumber ++;
            _releaseStages[stagesNumber].activationTime = timestamps[i];
            _releaseStages[stagesNumber].percentage = percentage[i];
        }
        _tokenReleaseStagesNumber = stagesNumber;
        return true;
    }

    function setRoundsData (
        uint256[] calldata usdRate,
        uint256[] calldata startTime,
        uint256[] calldata duration,
        uint256[] calldata maxAllocation
    ) external hasRole(MANAGER) returns (bool) {
        require(
            usdRate.length <= _maxRoundsNumber,
                'Array length can not be greater than _maxRoundsNumber'
        );
        require(
            usdRate.length == startTime.length
                && usdRate.length == duration.length
                && usdRate.length == maxAllocation.length,
            'Arrays should be of the same length'
        );
        uint8 roundsNumber;
        uint256 previousEndTime;
        for (uint256 i = 0; i < usdRate.length; i ++) {
            require(
                startTime[i] >= previousEndTime,
                    'Round can not start before previous round end'
            );
            roundsNumber ++;
            _rounds[roundsNumber].usdRate = usdRate[i];
            _rounds[roundsNumber].startTime = startTime[i];
            _rounds[roundsNumber].duration = duration[i];
            _rounds[roundsNumber].maxAllocation = maxAllocation[i];
            _rounds[roundsNumber].endTime = _rounds[roundsNumber].startTime
                + _rounds[roundsNumber].duration;
            previousEndTime = _rounds[roundsNumber].endTime;
        }
        _roundsNumber = roundsNumber;
        return true;
    }

    function setRoundUsdRate (
        uint8 roundIndex,
        uint256 usdRate
    ) external hasRole(MANAGER) returns (bool) {
        require(
            roundIndex > _activeRoundIndex,
                'This round can not be changed'
        );
        require(
            roundIndex <= _roundsNumber,
                'Invalid round number'
        );
        _rounds[roundIndex].usdRate = usdRate;
        return true;
    }

    function setRoundTime (
        uint8 roundIndex,
        uint256 startTime,
        uint256 endTime
    ) external hasRole(MANAGER) returns (bool) {
        require(
            roundIndex > _activeRoundIndex,
            'This round can not be changed'
        );
        require(
            roundIndex <= _roundsNumber,
            'Invalid round number'
        );
        require(
            endTime > startTime,
            'end time should be greater than start time'
        );
        if (roundIndex > 1) {
            require(
                startTime >=
                    _rounds[roundIndex - 1].endTime,
                'Round can not start before previous round end'
            );
        }
        if (roundIndex < _roundsNumber) {
            require(
                endTime <=
                    _rounds[roundIndex + 1].startTime,
                'Round can not end later than the next round start'
            );
        }
        _rounds[roundIndex].startTime = startTime;
        _rounds[roundIndex].endTime = endTime;
        _rounds[roundIndex].duration = _rounds[roundIndex].endTime
            - _rounds[roundIndex].startTime;
        return true;
    }

    function setRoundAllocation (
        uint8 roundIndex,
        uint256 maxAllocation
    ) external hasRole(MANAGER) returns (bool) {
        require(
            roundIndex > _activeRoundIndex,
            'This round can not be changed'
        );
        require(
            roundIndex <= _roundsNumber,
            'Invalid round number'
        );
        _rounds[roundIndex].maxAllocation = maxAllocation;
        return true;
    }

    function getUserPurchased (
        address userAddress
    ) external view returns (uint256) {
        return _purchasedAmount[userAddress];
    }

    function getReferralAmount (
        address userAddress
    ) external view returns (uint256) {
        return _referralAmount[userAddress];
    }

    function getUserWithdrawn (
        address userAddress
    ) external view returns (uint256) {
        return _withdrawnAmount[userAddress];
    }

    function getTotalPaid () external view returns (uint256) {
        return _usdTotalPaid;
    }

    function getTotalWithdrawn () external view returns (uint256) {
        return _totalWithdrawn;
    }

    function getTimestamp () external view returns (uint256) {
        return block.timestamp;
    }

    function getMaxPurchaseAmount () external view returns (uint256) {
        return _maxPurchaseAmount;
    }

    function getPaymentProfile (
        uint8 paymentProfileIndex
    ) external view returns (
        address contractAddress,
        uint256 weight,
        uint256 totalPaid,
        string memory name,
        string memory currency,
        bool active
    ) {
        return (
            _paymentProfiles[paymentProfileIndex].contractAddress,
            _paymentProfiles[paymentProfileIndex].weight,
            _paymentProfiles[paymentProfileIndex].totalPaid,
            _paymentProfiles[paymentProfileIndex].name,
            _paymentProfiles[paymentProfileIndex].currency,
            _paymentProfiles[paymentProfileIndex].active
        );
    }

    function getPaymentProfilesNumber () external view returns (uint256) {
        return _paymentProfilesNumber;
    }

    function getUserAvailable (
        address userAddress
    ) public view returns (uint256) {
        uint256 toWithdraw = (
            _purchasedAmount[userAddress] + _referralAmount[userAddress]
        ) * getAvailablePercentage() / SHIFT_4;
        if (toWithdraw < _withdrawnAmount[userAddress]) return 0;
        return toWithdraw - _withdrawnAmount[userAddress];
    }

    function getTokenReleaseStagesNumber () external view returns (uint256) {
        return _tokenReleaseStagesNumber;
    }

    function getTokenReleaseStageData (
        uint8 stageIndex
    ) external view returns (uint256 activationTime, uint16 percentage) {
        require(
            stageIndex > 0 && stageIndex <= _tokenReleaseStagesNumber,
            'Invalid stage number'
        );
        return (
            _releaseStages[stageIndex].activationTime,
            _releaseStages[stageIndex].percentage
        );
    }

    function getRoundData (
        uint8 roundIndex
    ) external view returns (
        uint256 usdRate,
        uint256 startTime,
        uint256 endTime,
        uint256 duration,
        uint256 maxAllocation,
        uint256 allocated
    ) {
        require(
            roundIndex <= _roundsNumber,
                'Invalid round number'
        );
        return (
            _rounds[roundIndex].usdRate,
            _rounds[roundIndex].startTime,
            _rounds[roundIndex].endTime,
            _rounds[roundIndex].duration,
            _rounds[roundIndex].maxAllocation,
            _rounds[roundIndex].allocated
        );
    }

    /**
     * @dev Function let use token realising schedule return % * 100
     */
    function getAvailablePercentage () public view returns (uint16) {
        uint16 percentage;
        if (_tokenReleaseStagesNumber == 0) return uint16(SHIFT_4);
        for (uint8 i = 1; i <= _tokenReleaseStagesNumber; i ++) {
            if (_releaseStages[i].activationTime > block.timestamp) break;
            percentage += _releaseStages[i].percentage;
        }
        if (percentage > SHIFT_4) percentage = uint16(SHIFT_4);
        return percentage;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
 * @dev Access control contract,
 * functions names are self explanatory
 */
contract AccessControl {
    modifier onlyOwner() {
        require(msg.sender == _owner, 'Caller is not the owner');
        _;
    }
    modifier hasRole(bytes32 role) {
        require(_checkRole(role, msg.sender), 'Caller is not authorized for this action'
        );
        _;
    }

    mapping (bytes32 => mapping(address => bool)) internal _roles;
    address internal _owner;

    constructor () {
        _owner = msg.sender;
    }

    /**
     * @dev Transfer ownership to another account
     */
    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), 'newOwner should not be zero address');
        _owner = newOwner;
        return true;
    }

    /**
     * @dev Grant role to account
     */
    function _grantRole (
        bytes32 role,
        address userAddress
    ) internal returns (bool) {
        _roles[role][userAddress] = true;
        return true;
    }

    /**
     * @dev Grant role to account
     */
    function grantRole (
        string memory role,
        address userAddress
    ) external onlyOwner returns (bool) {
        _grantRole(keccak256(abi.encode(role)), userAddress);
        return true;
    }

    /**
     * @dev Revoke role from account
     */
    function _revokeRole (
        bytes32 role,
        address userAddress
    ) internal returns (bool) {
        _roles[role][userAddress] = false;
        return true;
    }

    /**
     * @dev Revoke role from account
     */
    function revokeRole (
        string memory role,
        address userAddress
    ) external onlyOwner returns (bool) {
        _revokeRole(keccak256(abi.encode(role)), userAddress);
        return true;
    }

    /**
     * @dev Check is account has specific role
     */
    function _checkRole (
        bytes32 role,
        address userAddress
    ) internal view returns (bool) {
        return _roles[role][userAddress];
    }

    /**
     * @dev Check is account has specific role
     */
    function checkRole (
        string memory role,
        address userAddress
    ) external view returns (bool) {
        return _checkRole(keccak256(abi.encode(role)), userAddress);
    }

    /**
     * @dev Owner address getter
     */
    function owner() public view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import './TransferHelper.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Utils is ReentrancyGuard {
    function _takeAsset (
        address tokenAddress, address fromAddress, uint256 amount
    ) internal returns (bool) {
        require(tokenAddress != address(0), 'Token address should not be zero');
        TransferHelper.safeTransferFrom(
            tokenAddress, fromAddress, address(this), amount
        );
        return true;
    }

    function _sendAsset (
        address tokenAddress, address toAddress, uint256 amount
    ) internal nonReentrant returns (bool) {
        if (tokenAddress == address(0)) {
            require(address(this).balance >= amount,
                'Not enough contract balance');
            payable(toAddress).transfer(amount);
        } else {
            TransferHelper.safeTransfer(
                tokenAddress, toAddress, amount
            );
        }
        return true;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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