// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BBErrorsV01.sol";
import "./interfaces/IBBProfiles.sol";
import "./interfaces/IBBTiers.sol";
import "./interfaces/IBBSubscriptionsFactory.sol";
import "./interfaces/IBBSubscriptions.sol";
import "./interfaces/IBBPermissionsV01.sol";
import "./interfaces/IBBGasOracle.sol";
import "./BBSubscriptions.sol";

contract BBSubscriptionsFactory is IBBSubscriptionsFactory {
    event DeployedSubscription(
        address currency,
        address deployedAddress
    );

    event NewSubscriptionProfile(
        uint256 profileId,
        uint256 tierSetId,
        uint256 contribution
    );

    event EditContribution(
        uint256 profileId,
        uint256 contribution
    );

    struct SubscriptionProfile {
        uint256 tierSetId;
        uint256 contribution;
    }

    uint256 internal constant _contributionLower = 1;
    uint256 internal constant _contributionUpper = 100;

    uint256 internal constant _gracePeriod = 2 days;

    // Subscription profile ID => Subscription profile
    mapping(uint256 => SubscriptionProfile) internal _subscriptionProfiles;
    
    // ERC20 token => Deployed subscriptions contract
    mapping(address => address) internal _deployedSubscriptions;

    // Profile ID => Tier ID => Subscriber => ERC20 token
    mapping(uint256 => mapping(uint256 => mapping (address => address))) internal _subscriptionCurrencies;

    address internal _treasury;

    IBBGasOracle internal _gasOracle;

    // ERC20 token => Subscription fee
    mapping(address => uint256) internal _subscriptionFees;

    address internal _treasuryOwner;
    address internal _gasOracleOwner;
    address internal _subscriptionFeeOwner;

    IBBProfiles internal immutable _bbProfiles;
    IBBTiers internal immutable _bbTiers;

    constructor(address bbProfiles, address bbTiers, address treasury) {
        _bbProfiles = IBBProfiles(bbProfiles);
        _bbTiers = IBBTiers(bbTiers);

        _treasury = treasury;

        _treasuryOwner = msg.sender;
        _gasOracleOwner = msg.sender;
        _subscriptionFeeOwner = msg.sender;
    }

    /*
        @dev Reverts if profile ID does not exist

        @param Profile ID
    */
    modifier profileExists(uint256 profileId) {
        require(profileId < _bbProfiles.totalProfiles(), BBErrorCodesV01.PROFILE_NOT_EXIST);
        _;
    }

    /*
        @dev Reverts if tier set ID does not exist

        @param Profile ID
        @param Tier set ID
    */
    modifier tierSetExists(uint256 profileId, uint256 tierSetId) {
        require(profileId < _bbProfiles.totalProfiles(), BBErrorCodesV01.PROFILE_NOT_EXIST);
        require(tierSetId < _bbTiers.totalTierSets(profileId), BBErrorCodesV01.TIER_SET_NOT_EXIST);
        _;
    }

    /*
        @dev Reverts if msg.sender is not profile IDs owner

        @param Profile ID
    */
    modifier onlyProfileOwner(uint256 profileId) {
        (address profileOwner,,) = _bbProfiles.getProfile(profileId);
        require(profileOwner == msg.sender, BBErrorCodesV01.NOT_OWNER);
        _;
    }

    /*
        @dev Reverts if msg.sender is not treasury owner
    */
    modifier onlyTreasuryOwner {
        require(msg.sender == _treasuryOwner, BBErrorCodesV01.NOT_OWNER);
        _;
    }

    /*
        @dev Reverts if msg.sender is not gas oracle owner
    */
    modifier onlyGasOracleOwner {
        require(msg.sender == _gasOracleOwner, BBErrorCodesV01.NOT_OWNER);
        _;
    }

    /*
        @dev Reverts if msg.sender is not subscription fee owner
    */
    modifier onlySubscriptionFeeOwner {
        require(msg.sender == _subscriptionFeeOwner, BBErrorCodesV01.NOT_OWNER);
        _;
    }

    /*
        @notice Deploys the subscriptions contract of a ERC20 token

        @param ERC20 token

        @return The ERC20 tokens subscriptions contract
    */
    function deploySubscriptions(address currency) external override returns(address) {
        require(_deployedSubscriptions[currency] == address(0), BBErrorCodesV01.ZERO_ADDRESS);

        IBBSubscriptions subscriptions = new BBSubscriptions(address(_bbProfiles), address(_bbTiers), address(this), currency);
        
        _deployedSubscriptions[currency] = address(subscriptions);
        _subscriptionFees[currency] = 13500000;

        emit DeployedSubscription(currency, address(subscriptions));
        return address(subscriptions);
    }

    /*
        @notice Check if a ERC20 token has a deployed subscriptions contract

        @param ERC20 token

        @return True if ERC20 token has a deployed subscriptions contract, otherwise false
    */
    function isSubscriptionsDeployed(address currency) external view override returns (bool) {
        return _deployedSubscriptions[currency] != address(0);
    }

    /*
        @notice Get the address of a ERC20 tokens subscriptions contract

        @param ERC20 token

        @return ERC20 tokens subscriptions contract address
    */
    function getDeployedSubscriptions(address currency) external view override returns (address) {
        // Reverts if the ERC20 tokens subscriptions contract is not deployed
        require(_deployedSubscriptions[currency] != address(0));
        return _deployedSubscriptions[currency];
    }

    /*
        @notice Sets the treasury owner

        @param Treasury owner address
    */
    function setTreasuryOwner(address account) external override onlyTreasuryOwner {
        _treasuryOwner = account;
    }

    /*
        @notice Set the gas price owner

        @param Gas price owner address
    */
    function setGasOracleOwner(address account) external override onlyGasOracleOwner {
        _gasOracleOwner = account;
    }

    /*
        @notice Sets the subscription fee owner

        @param Subscription fee owner
    */
    function setSubscriptionFeeOwner(address account) external override onlySubscriptionFeeOwner {
        _subscriptionFeeOwner = account;
    }

    /*
        @notice Get the treasury owner

        @return Treasury address
    */
    function getTreasuryOwner() external view returns (address) {
        return _treasuryOwner;
    }

    /*
        @notice Get the gas oracle owner

        @return Gas price owner address
    */
    function getGasOracleOwner() external view returns (address) {
        return _gasOracleOwner;
    }
    
    /*
        @notice Get the subscription fee owner

        @return Subscription fee owner address
    */
    function getSubscriptionFeeOwner() external view returns (address) {
        return _subscriptionFeeOwner;
    }

    /*
        @notice Set the treasury address

        @param Treasury address
    */
    function setTreasury(address account) external override onlyTreasuryOwner {
        _treasury = account;
    }

    /*
        @notice Set the gas price oracle

        @param Gas price contract
    */
    function setGasOracle(address account) external override onlyGasOracleOwner {
        _gasOracle = IBBGasOracle(account);
    }

    /*
        @notice Set the subscription fee

        @param ERC20 token to set the subscription fee for
        @param Subscription fee
    */
    function setSubscriptionFee(address currency, uint256 amount) external override onlySubscriptionFeeOwner {
        require(_deployedSubscriptions[currency] != address(0), BBErrorCodesV01.UNSUPPORTED_CURRENCY);
        _subscriptionFees[currency] = amount;
    }

    /*
        @notice Get the treasury address

        @return Treasury address
    */
    function getTreasury() external view override returns (address treasury) {
        return _treasury;
    }

    /*
        @notice Get the gas oracles address

        @return Gas oracle
    */
    function getGasOracle() external view override returns (address oracle) {
        return address(_gasOracle);
    }

    /*
        @notice Get the subscription fee

        @param ERC20 token to set the subscription fee for

        @return Subscription fee
    */
    function getSubscriptionFee(address currency) external view returns (uint256 fee) {
        require(_deployedSubscriptions[currency] != address(0), BBErrorCodesV01.UNSUPPORTED_CURRENCY);
        return _subscriptionFees[currency] * _gasOracle.getGasPrice();
    }

    /*
        @notice Get the subscription expiration grace period

        @return Grace period in seconds
    */
    function getGracePeriod() external pure override returns (uint256) {
        return _gracePeriod;
    }
    
    /*
        @notice Get the treasury contribution bounds

        @return Lower bound
        @return Upper bound
    */
    function getContributionBounds() external pure override returns (uint256, uint256) {
        return (_contributionLower, _contributionUpper);
    }

    /*
        @dev Set a subscriptions ERC20 token

        @param Profile ID
        @param Tier ID
        @param Subscriber
        @param ERC20 token
    */
    function setSubscriptionCurrency(uint256 profileId, uint256 tierId, address account, address currency) profileExists(profileId) external override {
        // Msg.sender must be the ERC20 tokens subscriptions contract
        require(msg.sender == _deployedSubscriptions[currency], BBErrorCodesV01.NOT_OWNER);
        _subscriptionCurrencies[profileId][tierId][account] = currency;
    }

    /*
        @notice Get a subscriptions ERC20 token

        @param Profile ID
        @param Tier ID
        @param Subscriber

        @return ERC20 token
    */
    function getSubscriptionCurrency(uint256 profileId, uint256 tierId, address account) external view override profileExists(profileId) returns (address) {
        // Subscription isn't active if subscriptions ERC20 token is the zero address, so revert
        require(_subscriptionCurrencies[profileId][tierId][account] != address(0));
        return _subscriptionCurrencies[profileId][tierId][account];
    }

    /*
        @notice Create a new subscription profile

        @param Profile ID
        @param Tier set ID
        @param Contribution
    */
    function createSubscriptionProfile(uint256 profileId, uint256 tierSetId, uint256 contribution) external override tierSetExists(profileId, tierSetId) onlyProfileOwner(profileId) {
        // Subscription profile already initialized
        require(_subscriptionProfiles[profileId].tierSetId == 0, BBErrorCodesV01.SUBSCRIPTION_PROFILE_ALREADY_EXISTS);

        _setContribution(profileId, contribution);
        // Add one to tier set ID so can also be used like a bool, zero means the value is uninitialized, greater than zero is the tier set ID minus one
        _subscriptionProfiles[profileId].tierSetId = tierSetId + 1;

        emit NewSubscriptionProfile(profileId, tierSetId, contribution);
    }

    /*
        @notice Get a subscription profile

        @param Profile ID

        @return Tier set ID
        @return Treasury contribution
    */
    function getSubscriptionProfile(uint256 profileId) external view override profileExists(profileId) returns (uint256, uint256) {
        // If subscription profile isnt initialized, tier set ID is zero, and so this reverts
        return (_subscriptionProfiles[profileId].tierSetId - 1, _subscriptionProfiles[profileId].contribution);
    }

    /*
        @notice Check a subscription profile is created

        @param Profile ID

        @return True if subscription profile is created, otherwise false
    */
    function isSubscriptionProfileCreated(uint256 profileId) external view override profileExists(profileId) returns (bool) {
        return _subscriptionProfiles[profileId].tierSetId > 0;
    }

    /*
        @notice Set a subscription profiles treasury contribution

        @param Profile ID
        @param Treasury contribution
    */
    function setContribution(uint256 profileId, uint256 contribution) external override profileExists(profileId) onlyProfileOwner(profileId){
        _setContribution(profileId, contribution);
        emit EditContribution(profileId, contribution);
    }

    /*
        @dev Set a subscription profiles treasury contribution

        @param Profile ID
        @param Treasury contribution
    */
    function _setContribution(uint256 profileId, uint256 contribution) internal {
        require(contribution >= _contributionLower, BBErrorCodesV01.OUT_OF_BOUNDS);
        require(contribution <= _contributionUpper, BBErrorCodesV01.OUT_OF_BOUNDS);

        _subscriptionProfiles[profileId].contribution = contribution;
    }

    /*
        @notice Check if an address has an active subscription to a profile tier

        @param Profile ID
        @param Tier ID
        @param Subscriber

        @return True if the subscription is active, otherwise false
    */
    function isSubscriptionActive(uint256 profileId, uint256 tierId, address account) external view override profileExists(profileId) returns (bool) {
        (address profileOwner,,) = _bbProfiles.getProfile(profileId);

        // Profile owner is always subscribed
        if(profileOwner == account) {
            return true;
        }

        // If profile owner is a contract, try checking for BackedBy permissions
        if(profileOwner.code.length > 0) {
            try IBBPermissionsV01(profileOwner).canViewSubscription(account) returns (bool success) {
                if(success)
                    return success;
            } catch { }
        }

        // If the subscription has no ERC20 token set, its not active
        if(_subscriptionCurrencies[profileId][tierId][account] == address(0)) {
            return false;
        }

        // Get subscription values from deployed subscriptions contract
        IBBSubscriptions subscriptions = IBBSubscriptions(_deployedSubscriptions[_subscriptionCurrencies[profileId][tierId][account]]);
        (,,uint256 expiration,) = subscriptions.getSubscriptionFromProfile(profileId, tierId, account);

        // If expiration plus grace period has elapsed, subscription is no longer active
        return block.timestamp < expiration + _gracePeriod;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./utils/DateTimeLibrary.sol";
import "./BBErrorsV01.sol";
import "./interfaces/IBBGasOracle.sol";
import "./interfaces/IBBProfiles.sol";
import "./interfaces/IBBTiers.sol";
import "./interfaces/IBBSubscriptionsFactory.sol";
import "./interfaces/IBBSubscriptions.sol";

contract BBSubscriptions is IBBSubscriptions {   
    event Subscribed(
        uint256 subscriptionId
    );

    event Renewed(
        uint256 subscriptionId
    );

    event Unsubscribed (
        uint256 subscriptionId
    );

    struct Subscription {
        uint256 profileId;
        uint256 tierId;
        address subscriber;
        uint256 price;
        uint256 expiration;
        bool cancelled;
    }

    // Subscription ID => Subscription
    mapping (uint256 => Subscription) internal _subscriptions;
    uint256 internal _totalSubscriptions;

    // Profile ID => Tier ID => Subscriber => Subscription ID + 1
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) internal _subscriptionIndexes;

    IBBProfiles internal immutable _bbProfiles;
    IBBTiers internal immutable _bbTiers;
    IBBSubscriptionsFactory internal immutable _bbSubscriptionsFactory;

    IERC20 internal immutable _currency;

    constructor(address bbProfiles, address bbTiers, address bbSubscriptionsFactory, address currency) {
        _bbProfiles = IBBProfiles(bbProfiles);
        _bbTiers = IBBTiers(bbTiers);
        _bbSubscriptionsFactory = IBBSubscriptionsFactory(bbSubscriptionsFactory);

        _currency = IERC20(currency);
    }

    /*
        @dev Transfer ERC20 tokens from address to profile receiver and treasury

        @param ERC20 token owner
        @param ERC20 token receiver
        @param ERC20 token amount
        @param Treasury contribution percentage

        @return True if transfer succeeded, otherwise false
    */
    function _pay(address owner, address receiver, uint256 amount, uint256 treasuryContribution) internal returns (bool) {
        // Check that the contract has enough allowance to process this transfer
        if ((_currency.allowance(owner, address(this)) >= amount) && _currency.balanceOf(owner) >= amount) { 
            _currency.transferFrom(owner, address(this), amount);

            uint256 receiverAmount = (amount * (100 - treasuryContribution)) / 100;

            if(receiverAmount > 0) {
                _currency.transfer(receiver, receiverAmount);
            }

            // Payment processed
            return true;
        } 

        // Insufficient funds
        return false;
    }

    /*
        @notice Renew subscriptions within a range

        @param Array of subscription IDs to renew and refund receiver packed into bytes array
    */
    function performUpkeep(bytes calldata renewalData) external override {
        (uint256[] memory renewIndexes, address refundReceiver) = abi.decode(renewalData, (uint256[], address));
        
        uint256 gasAtStart = gasleft();
        uint256 renewCount;

        for(uint256 i; i < renewIndexes.length; i++) {
            require(renewIndexes[i] < _totalSubscriptions, BBErrorCodesV01.SUBSCRIPTION_NOT_EXIST);

            if(_subscriptions[renewIndexes[i]].expiration < block.timestamp && _subscriptions[renewIndexes[i]].cancelled == false) {
                (uint256 tierSetId, uint256 contribution) = _bbSubscriptionsFactory.getSubscriptionProfile(_subscriptions[renewIndexes[i]].profileId);

                // Check the subscription tier still exists, and the token is still accepted by the creator
                if(_subscriptions[renewIndexes[i]].tierId < _bbTiers.totalTiers(_subscriptions[renewIndexes[i]].profileId, tierSetId) && _bbTiers.isCurrencySupported(_subscriptions[renewIndexes[i]].profileId, tierSetId, address(_currency))) {
                    (,address profileReceiver,) = _bbProfiles.getProfile(_subscriptions[renewIndexes[i]].profileId);

                    bool paid = _pay(
                        _subscriptions[renewIndexes[i]].subscriber,
                        profileReceiver,
                        _subscriptions[renewIndexes[i]].price,
                        contribution
                    );

                    if(paid) {
                        // Subscription payment succeeded, so extended expiration timestamp
                        _subscriptions[renewIndexes[i]].expiration = block.timestamp + (DateTimeLibrary.getDaysInMonth(block.timestamp) * 1 days);    

                        renewCount++;

                        emit Renewed(renewIndexes[i]); 
                        continue;
                    }
                }

                // Subscription payment failed, or subscription tier no longer exists, therefore cancel the subscription
                _subscriptions[renewIndexes[i]].cancelled = true;

                emit Unsubscribed(renewIndexes[i]);

                renewCount++;
            }
        }

        require(renewCount > 0, BBErrorCodesV01.UPKEEP_FAIL);

        // Calculate the gas refund, add 30327 gas for the rest of the function, 26215 for decoding the renewal data, and 423 multiplied by the number of indexes renewed
        uint256 gasBudget = _getUpkeepRefund() * renewCount;
        uint256 refund = (gasAtStart - gasleft() + (56542 + (423 * renewCount))) * IBBGasOracle(_bbSubscriptionsFactory.getGasOracle()).getGasPrice();
        // Invalid ID refund penalty
        refund = refund - ((refund / renewIndexes.length) * (renewIndexes.length - renewCount));

        // Check the refund isnt greater than the gas budget
        if (refund > gasBudget) {
            refund = gasBudget;
        }

        // Check if refund is greater than the balance.
        if(address(this).balance < refund) {
            refund = address(this).balance;
        }

        // Transfer gas refund to refund receiver
        if(refund > 0) {
            refundReceiver.call{value: refund}("");
        }
    }

    /*
        @notice Subscribe to a profile

        @param Profile ID
        @param Tier ID
        
        @return Subscription ID
    */
    function subscribe(uint256 profileId, uint256 tierId) external payable override returns(uint256 subscriptionId) {
        require(msg.value >= _bbSubscriptionsFactory.getSubscriptionFee(address(_currency)), BBErrorCodesV01.INSUFFICIENT_PREPAID_GAS);

        if(_bbSubscriptionsFactory.isSubscriptionActive(profileId, tierId, msg.sender) == true) {
            (,,,bool cancelled) = IBBSubscriptions(_bbSubscriptionsFactory.getDeployedSubscriptions(_bbSubscriptionsFactory.getSubscriptionCurrency(profileId, tierId, msg.sender))).getSubscriptionFromProfile(profileId, tierId, msg.sender);
            require(cancelled == true, BBErrorCodesV01.SUBSCRIPTION_ACTIVE);
        }

        (uint256 tierSet,) = _bbSubscriptionsFactory.getSubscriptionProfile(profileId);

        (,uint256 price, bool deprecated) = _bbTiers.getTier(profileId, tierSet, tierId, address(_currency));

        require(deprecated == false, BBErrorCodesV01.TIER_NOT_EXIST);

        subscriptionId = _totalSubscriptions;

        if(_subscriptionIndexes[profileId][tierId][msg.sender] == 0) {
            _subscriptionIndexes[profileId][tierId][msg.sender] = _totalSubscriptions + 1;
            _totalSubscriptions++;
        }
        else {
            subscriptionId = _subscriptionIndexes[profileId][tierId][msg.sender] - 1;
        }

        _subscriptions[subscriptionId] = Subscription(
            profileId, 
            tierId, 
            msg.sender, 
            price,
            block.timestamp + 30 days, 
            false
        ); 

        (,address profileReceiver,) = _bbProfiles.getProfile(profileId);
        (,uint256 contribution) = _bbSubscriptionsFactory.getSubscriptionProfile(profileId);

        require(_pay(msg.sender, profileReceiver, price, contribution), BBErrorCodesV01.INSUFFICIENT_BALANCE);

        _bbSubscriptionsFactory.setSubscriptionCurrency(profileId, tierId, msg.sender, address(_currency));

        withdrawToTreasury();

        emit Subscribed(subscriptionId);
    }

    /*
        @notice Unsubscribe from a profile

        @param Profile ID
        @param Tier ID        
    */
    function unsubscribe(uint256 profileId, uint256 tierId) external override {
        uint256 id = _getSubscriptionId(profileId, tierId, msg.sender);
        require(_subscriptions[id].subscriber == msg.sender, BBErrorCodesV01.NOT_SUBSCRIPTION_OWNER);
        require(_subscriptions[id].cancelled == false, BBErrorCodesV01.SUBSCRIPTION_CANCELLED);

        _subscriptions[id].cancelled = true;

        emit Unsubscribed(id);
    }

    /*
        @notice Check if there are subscriptions to renew within a range

        @param Lower bound, upper bound, minimum number of IDs to renew, maximum number of IDs to renew, and refund receiver packed into bytes array

        @return True if there are subscriptions to renew within the lower and upper bound, otherwise false
        @return Array of subscription IDs to renew and refund receiver packed into bytes array
    */
    function checkUpkeep(bytes calldata checkData) external view override returns (bool, bytes memory) {
        (uint256 lowerBound, uint256 upperBound, uint256 minRenews, uint256 maxRenews, address refundReceiver) = abi.decode(checkData, (uint256, uint256, uint256, uint256, address));

        // Limit upper bound within total subscriptions
        if(upperBound >= _totalSubscriptions) {
            upperBound = _totalSubscriptions - 1;
        }

        // Lower bound must be less than upper bound
        require(lowerBound <= upperBound, BBErrorCodesV01.OUT_OF_BOUNDS);

        uint256 renewalCount;
        uint256 checkLength = (upperBound - lowerBound) + 1;

        uint256[] memory maxRenewIndexes = new uint256[](maxRenews);

        for(uint256 i; i < checkLength; i++) {
            uint256 subscriptionIndex = lowerBound + i;

            // If subscription has expired, increment total number of subscriptions to renew
            if(_subscriptions[subscriptionIndex].expiration < block.timestamp && _subscriptions[subscriptionIndex].cancelled == false) {               
                maxRenewIndexes[renewalCount] = subscriptionIndex;
                renewalCount++;

                if(renewalCount >= maxRenews) {
                    break;
                }
            }
        }

        // If subscriptions to renew is zero or less than minimum required renewals, return false
        if(renewalCount == 0 || renewalCount < minRenews) {
            return (false, "");
        }

        // Return the maximum number of indexes that can be renewed
        if(renewalCount == maxRenews) {
            return (true, abi.encode(maxRenewIndexes, refundReceiver));
        }

        // Resize renewal indexes array
        uint256[] memory renewIndexes = new uint256[](renewalCount);

        for(uint256 i; i < renewalCount; i++) {
            renewIndexes[i] = maxRenewIndexes[i];
        }

        return (true, abi.encode(renewIndexes, refundReceiver));
    }

    /*
        @notice Transfers this contracts tokens to the subscription factory treasury
    */
    function withdrawToTreasury() public {
        _currency.transfer(_bbSubscriptionsFactory.getTreasury(), _currency.balanceOf(address(this)));
    }

    /*
        @notice Get a subscriptions values

        @param Profile ID
        @param Tier ID
        @param Subscriber

        @return Subscription ID
        @return Price (monthly)
        @return Expiration
        @return Subscription cancelled
    */
    function getSubscriptionFromProfile(uint256 profileId, uint256 tierId, address subscriber) external view returns (uint256, uint256, uint256, bool) {
        uint256 id = _getSubscriptionId(profileId, tierId, subscriber);

        return (
            id,
            _subscriptions[id].price,
            _subscriptions[id].expiration,
            _subscriptions[id].cancelled
        );
    }

    /*
        @notice Get a subscriptions values

        @param Subscription ID

        @return Profile ID
        @return Tier ID
        @return Subscriber
        @return Price (monthly)
        @return Expiration
        @return Subscription cancelled
    */
    function getSubscriptionFromId(uint256 subscriptionId) external view returns (uint256, uint256, address, uint256, uint256, bool) {
        return (
            _subscriptions[subscriptionId].profileId,
            _subscriptions[subscriptionId].tierId,
            _subscriptions[subscriptionId].subscriber,
            _subscriptions[subscriptionId].price,
            _subscriptions[subscriptionId].expiration,
            _subscriptions[subscriptionId].cancelled
        );
    }

    /*
        @dev Get a subscription ID

        @param Profile ID
        @param Tier ID
        @param Subscriber

        @return Subscription ID
    */
    function _getSubscriptionId(uint256 profileId, uint256 tierId, address subscriber) internal view returns (uint256) {
        require(_subscriptionIndexes[profileId][tierId][subscriber] > 0, BBErrorCodesV01.SUBSCRIPTION_NOT_EXIST);
        return _subscriptionIndexes[profileId][tierId][subscriber] - 1;
    }

    /*
        @dev Gets the upkeep gas refund

        @return Upkeep gas refund
    */
    function _getUpkeepRefund() internal view returns (uint256) {
        return _bbSubscriptionsFactory.getSubscriptionFee(address(_currency)) / 60;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBBGasOracle {
    function getGasPrice() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBBPermissionsV01 {
    function canViewSubscription(address account) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IBBSubscriptions is KeeperCompatibleInterface {
    function subscribe(uint256 profileId, uint256 tierId) external payable returns(uint256 subscriptionId);
    function unsubscribe(uint256 profileId, uint256 tierId) external;
    
    function withdrawToTreasury() external;

    function getSubscriptionFromProfile(uint256 profileId, uint256 tierId, address subscriber) external view returns (uint256 subscriptionId, uint256 price, uint256 expiration, bool cancelled);
    function getSubscriptionFromId(uint256 subscriptionId) external view returns (uint256 profileId, uint256 tierId, address subscriber, uint256 price, uint256 expiration, bool cancelled);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBBSubscriptionsFactory {
    function deploySubscriptions(address currency) external returns(address subscriptions);
    function isSubscriptionsDeployed(address currency) external view returns (bool deployed);
    function getDeployedSubscriptions(address currency) external view returns (address subscriptions);

    function setTreasuryOwner(address account) external;
    function setGasOracleOwner(address account) external;
    function setSubscriptionFeeOwner(address account) external;

    function getTreasuryOwner() external view returns (address treasury);
    function getGasOracleOwner() external view returns (address gasPriceOwner);
    function getSubscriptionFeeOwner() external view returns (address subscriptionFeeOwner);

    function setTreasury(address account) external;
    function setGasOracle(address account) external;
    function setSubscriptionFee(address currency, uint256 amount) external;

    function getTreasury() external view returns (address treasury);
    function getGasOracle() external view returns (address oracle);
    function getSubscriptionFee(address currency) external view returns (uint256 fee);

    function getGracePeriod() external pure returns (uint256 gracePeriod);
    function getContributionBounds() external pure returns (uint256 lower, uint256 upper);

    function setSubscriptionCurrency(uint256 profileId, uint256 tierId, address account, address currency) external;
    function getSubscriptionCurrency(uint256 profileId, uint256 tierId, address account) external view returns (address currency);

    function createSubscriptionProfile(uint256 profileId, uint256 tierSetId, uint256 contribution) external;
    function setContribution(uint256 profileId, uint256 contribution) external;

    function getSubscriptionProfile(uint256 profileId) external view returns (uint256 tierSetId, uint256 contribution);
    function isSubscriptionProfileCreated(uint256 profileId) external view returns (bool created);

    function isSubscriptionActive(uint256 profileId, uint256 tierId, address account) external view returns (bool active);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBBTiers {
    function createTiers(uint256 profileId, uint256[] calldata prices, string[] calldata cids, bool[] memory deprecated, address[] calldata supportedCurrencies, uint256[] calldata priceMultipliers) external returns(uint256 tierSetId);
    function editTiers(uint256 profileId, uint256 tierSetId, uint256[] calldata prices, string[] calldata cids, bool[] memory deprecated) external;
    function setSupportedCurrencies(uint256 profileId, uint256 tierSetId, address[] calldata supportedCurrencies, uint256[] calldata priceMultipliers) external;

    function getTier(uint256 profileId, uint256 tierSetId, uint256 tierId, address currency) external view returns (string memory, uint256, bool);
    function getTierSet(uint256 profileId, uint256 tierSetId) external view returns (uint256[] memory prices, string[] memory cids, bool[] memory deprecated);

    function totalTiers(uint256 profileId, uint256 tierSetId) external view returns (uint256 total);
    function totalTierSets(uint256 profileId) external view returns (uint256 total);

    function getCurrencyMultiplier(uint256 profileId, uint256 tierSetId, address currency) external view returns (uint256 multiplier);
    function isCurrencySupported(uint256 profileId, uint256 tierSetId, address currency) external view returns (bool supported);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBBProfiles {
    function createProfile(address owner, address receiver, string calldata cid) external returns(uint256 profileId);
    function editProfile(uint256 profileId, address owner, address receiver, string calldata cid) external; 

    function totalProfiles() external view returns (uint256 total);
    function getProfile(uint256 profileId) external view returns (address owner, address receiver, string memory cid);

    function getOwnersProfiles(address account) external view returns (uint256[] memory profileIds);
    function ownersTotalProfiles(address owner) external view returns (uint256 total);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library BBErrorCodesV01 {
    string public constant NOT_OWNER = "1";
    string public constant OUT_OF_BOUNDS = "2";
    string public constant NOT_SUBSCRIPTION_OWNER = "3";
    string public constant POST_NOT_EXIST = "4";
    string public constant PROFILE_NOT_EXIST = "5";
    string public constant TIER_SET_NOT_EXIST = "6";
    string public constant TIER_NOT_EXIST = "7";
    string public constant SUBSCRIPTION_NOT_EXIST = "8";
    string public constant ZERO_ADDRESS = "9";
    string public constant SUBSCRIPTION_NOT_EXPIRED = "10";
    string public constant SUBSCRIPTION_CANCELLED = "11";
    string public constant UPKEEP_FAIL = "12";
    string public constant INSUFFICIENT_PREPAID_GAS = "13";
    string public constant INSUFFICIENT_ALLOWANCE = "14";
    string public constant INSUFFICIENT_BALANCE = "15";
    string public constant SUBSCRIPTION_ACTIVE = "16";
    string public constant INVALID_LENGTH = "17";
    string public constant UNSUPPORTED_CURRENCY = "18";
    string public constant SUBSCRIPTION_PROFILE_ALREADY_EXISTS = "19";
    string public constant INVALID_PRICE = "20";
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// adapted from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary

library DateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
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
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}