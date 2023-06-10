// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IERC20.sol";
import "../utils/ReentrancyGuard.sol";

/**
 * @title CryptoAssetInsuranceFactory
 * @dev A contract for creating and managing crypto asset insurance contracts.
 */

contract CryptoAssetInsuranceFactory {
    /////////////////////////
    // Errors   /////////////
    /////////////////////////
    error InvalidPlan();
    error InvalidOracleAddress();
    error ZeroAddress();
    error InsufficientInitialValue();
    error onlyOwner();
    error InsufficientContractBalance();
    error FailedToSendFunds();
    error InsuranceAlreadyPurchased();
    error InvalidTokenAmount();
    error InsufficientFunds();
    error InvalidCustomer();
    error InvalidClaimAmount();

    /////////////////////////
    // Variables ////////////
    /////////////////////////

    address immutable owner;
    address immutable ethToUsd;
    mapping(address => address) public customerToContract;
    mapping(address => address) public contractToCustomer;
    mapping(uint8 => uint8) public plans;
    address[] customers;

    /////////////////////////
    // Events   /////////////
    /////////////////////////

    event InsurancePurchased(address indexed customer, address indexed contractAddress, uint256 amount);
    event ClaimedInsurance(address indexed contractAddress, uint256 amount);

    /////////////////////////
    // Functions ////////////
    /////////////////////////

    /////////////////////////
    // Constructor //////////
    /////////////////////////

    /**
     * @dev Constructor function.
     * @param _ethToUsd The address of the ETH to USD price oracle contract.
     */
    constructor(address _ethToUsd) payable {
        if (msg.value < 0.1 ether) {
            revert InsufficientInitialValue();
        }
        if (_ethToUsd == address(0)) {
            revert ZeroAddress();
        }
        owner = msg.sender;
        plans[1] = 1;
        plans[2] = 5;
        plans[3] = 10;
        ethToUsd = _ethToUsd;
    }

    /////////////////////////
    // Receive   ////////////
    /////////////////////////

    receive() external payable {}

    /**
     * @dev Withdraws the specified amount of funds from the contract to the owner's address.
     * @param amount The amount of funds to withdraw.
     */
    function withdraw(uint256 amount) public payable {
        if (msg.sender != owner) {
            revert onlyOwner();
        }
        if (address(this).balance < amount) {
            revert InsufficientContractBalance();
        }
        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) {
            revert FailedToSendFunds();
        }
    }

    /////////////////////////
    // Public Functions /////
    /////////////////////////

    /**
     * @dev Creates a new insurance contract for the specified asset.
     * @param plan The insurance plan (1, 2, or 3).
     * @param assetAddress The address of the asset token.
     * @param timePeriod The insurance time period.
     * @param oracleAddress The address of the price oracle contract for the asset.
     * @param decimals The number of decimals for the asset.
     * @param tokensInsured The number of tokens to be insured.
     */
    function getInsurance(
        uint8 plan,
        address assetAddress,
        uint256 timePeriod,
        address oracleAddress,
        uint256 decimals,
        uint256 tokensInsured
    ) public payable {
        if (customerToContract[msg.sender] != address(0)) {
            revert InsuranceAlreadyPurchased();
        }
        uint256 totalTokens = getTokenBalance(assetAddress, msg.sender);
        if (tokensInsured <= 0 || tokensInsured > totalTokens) {
            revert InvalidTokenAmount();
        }
        uint8 _plan = plans[plan];
        if (_plan == 0) {
            revert InvalidPlan();
        }
        uint256 priceAtInsurance = getFeedValueOfAsset(oracleAddress);
        uint256 pricePayable = calculateDepositMoney(tokensInsured, _plan, priceAtInsurance, decimals, timePeriod);
        if (msg.value < pricePayable) {
            revert InsufficientFunds();
        }
        address insuranceContract = address(
            new AssetWalletInsurance(
                msg.sender,
                assetAddress,
                tokensInsured,
                _plan,
                timePeriod,
                (address(this)),
                oracleAddress,
                priceAtInsurance,
                decimals
            )
        );
        customerToContract[msg.sender] = insuranceContract;
        contractToCustomer[insuranceContract] = msg.sender;
        customers.push(msg.sender);
        emit InsurancePurchased(msg.sender, insuranceContract, pricePayable);
    }

    /**
     * @dev Allows an insurance contract to claim the insurance amount.
     */
    function claimInsurance() public payable {
        require(contractToCustomer[msg.sender] != address(0), "Only insurance contracts can call this function");
        if (contractToCustomer[msg.sender] == address(0)) {
            revert InvalidCustomer();
        }
        AssetWalletInsurance instance = AssetWalletInsurance(payable(msg.sender));
        uint256 _claimAmount = instance.getClaimAmount();
        uint256 _decimals = instance.decimals();
        if (_claimAmount == 0) {
            revert InvalidClaimAmount();
        }
        uint256 conversionRate = getUsdToWei();
        uint256 amountSent = (conversionRate * _claimAmount) / 10 ** _decimals;
        if (amountSent > address(this).balance) {
            revert InsufficientFunds();
        }
        (bool sent,) = msg.sender.call{value: amountSent}("");
        if (!sent) {
            revert FailedToSendFunds();
        }
        emit ClaimedInsurance(msg.sender, amountSent);
    }

    /////////////////////////
    // View Functions ///////
    /////////////////////////

    /**
     * @dev Returns the owner of the contract.
     * @return The address of the contract owner.
     */
    function getOwner() public view returns (address) {
        return owner;
    }

    /**
     * @dev Returns an array of customer addresses.
     * @return An array of customer addresses.
     */
    function getCustomers() public view returns (address[] memory) {
        return customers;
    }

    /**
     * @dev Returns the insurance contract address associated with the given customer address.
     * @param customerAddress The customer address.
     * @return The insurance contract address.
     */
    function getCustomerToContract(address customerAddress) public view returns (address) {
        return customerToContract[customerAddress];
    }

    /**
     * @dev Returns the balance of the specified token for the given account address.
     * @param tokenAddress The address of the token.
     * @param accountAddress The account address.
     * @return The token balance.
     */
    function getTokenBalance(address tokenAddress, address accountAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(accountAddress);
    }

    /**
     * @dev Returns the latest feed value of the specified asset from the given oracle address.
     * @param _oracleAddress The address of the price oracle contract.
     * @return The latest feed value.
     */
    function getFeedValueOfAsset(address _oracleAddress) public view returns (uint256) {
        AggregatorV3Interface priceConsumer = AggregatorV3Interface(_oracleAddress);
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt */
            ,
            /*uint timeStamp */
            ,
            /*uint80 answeredInRound */
        ) = priceConsumer.latestRoundData();
        return uint256(price);
    }

    /**
     * @dev Returns the conversion rate from USD to Wei.
     * @return The conversion rate.
     */
    function getUsdToWei() public view returns (uint256) {
        AggregatorV3Interface priceConsumer = AggregatorV3Interface(ethToUsd);
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt */
            ,
            /*uint timeStamp */
            ,
            /*uint80 answeredInRound */
        ) = priceConsumer.latestRoundData();
        return uint256((10 ** 26) / price);
    }

    /**
     * @dev Calculates the deposit amount required for the insurance.
     * @param _tokens The number of tokens.
     * @param _plan The insurance plan (1, 2, or 3).
     * @param _priceAtInsurance The price of the asset at the time of insurance.
     * @param _decimals The number of decimals for the asset.
     * @param _timePeriod The insurance time period.
     * @return The deposit amount payable.
     */
    function calculateDepositMoney(
        uint256 _tokens,
        uint256 _plan,
        uint256 _priceAtInsurance,
        uint256 _decimals,
        uint256 _timePeriod
    ) public view returns (uint256) {
        uint256 conversionRate = getUsdToWei();
        uint256 pricePayable =
            (_priceAtInsurance * _tokens * _plan * _timePeriod * conversionRate) / (10 ** (_decimals * 2 + 2));
        return pricePayable;
    }
}

/**
 * @title AssetWalletInsurance
 * @dev Contract representing the insurance for an asset wallet.
 */
contract AssetWalletInsurance is ReentrancyGuard {
    //////////////////////////
    // Errors   //////////////
    //////////////////////////
    error OnlyOwner();
    error TransactionFailed();
    error AlreadyClaimedReward();
    error InvalidClaimAmount();
    error InsuranceExpired();
    error NoChangeInAssetPrice();

    //////////////////////////
    // State Variables ///////
    //////////////////////////
    address public immutable owner;
    address public immutable assetAddress;
    uint256 public immutable tokensInsured;
    uint256 public immutable plan;
    uint256 public immutable timePeriod;
    uint256 public claimAmount;
    address public immutable factoryContract;
    address public immutable oracleAddress;
    uint256 public immutable priceAtInsurance;
    uint256 public immutable decimals;
    bool public claimed;

    //////////////////////////
    // Modifiers /////////////
    //////////////////////////

    /**
     * @dev Modifier to check if the caller is the owner of the insurance contract.
     */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    //////////////////////////
    // Functions /////////////
    //////////////////////////

    /////////////////////////
    // Constructor //////////
    /////////////////////////

    /**
     * @dev Initializes the insurance contract.
     * @param _owner The address of the wallet owner.
     * @param _assetAddress The address of the asset token.
     * @param _tokensInsured The number of tokens insured.
     * @param _plan The insurance plan (1, 2, or 3).
     * @param _timePeriod The insurance time period in months.
     * @param _factoryContract The address of the insurance factory contract.
     * @param _oracleAddress The address of the price oracle contract for the asset.
     * @param _priceAtInsurance The price of the asset at the time of insurance.
     * @param _decimals The number of decimals for the asset.
     */
    constructor(
        address _owner,
        address _assetAddress,
        uint256 _tokensInsured,
        uint256 _plan,
        uint256 _timePeriod,
        address _factoryContract,
        address _oracleAddress,
        uint256 _priceAtInsurance,
        uint256 _decimals
    ) {
        owner = _owner;
        assetAddress = _assetAddress;
        tokensInsured = _tokensInsured;
        plan = _plan;
        timePeriod = block.timestamp + _timePeriod * 2629743; // validity in minutes (assuming 30 days per month)
        factoryContract = _factoryContract;
        oracleAddress = _oracleAddress;
        priceAtInsurance = _priceAtInsurance;
        decimals = _decimals;
    }

    /////////////////////////
    // Receive Function /////
    /////////////////////////

    receive() external payable {}

    /////////////////////////
    // External Functions ///
    /////////////////////////

    /**
     * @dev Allows the owner of the insurance contract to claim the insurance amount.
     */
    function claimInsurance() external nonReentrant onlyOwner {
        verifyInsurance();
        if (claimAmount == 0) {
            revert InvalidClaimAmount();
        }
        (bool sent,) = msg.sender.call{value: claimAmount}("");
        if (!sent) {
            revert TransactionFailed();
        }
        claimed = true;
    }

    /////////////////////////
    // Public Functions /////
    /////////////////////////

    /**
     * @dev Allows the owner of the insurance contract to withdraw the claim amount.
     */
    function withdrawClaim() public payable onlyOwner {
        (bool success,) = owner.call{value: address(this).balance}("");
        if (!success) {
            revert TransactionFailed();
        }
    }

    /**
     * @dev Allows the owner of the insurance contract to claim the insurance amount and receive the value in Ether.
     */
    function claim() public onlyOwner {
        if (claimed) {
            revert AlreadyClaimedReward();
        }
        verifyInsurance();
        claimed = true;
        (bool success,) = factoryContract.call(abi.encodeWithSignature("claimInsurance()"));
        if (!success) {
            revert TransactionFailed();
        }
    }

    /////////////////////////
    // Internal Functions ///
    /////////////////////////

    /**
     * @dev Verifies the insurance and sets the claim amount.
     */
    function verifyInsurance() internal onlyOwner {
        if (block.timestamp > timePeriod) {
            revert InsuranceExpired();
        }
        if (claimed) {
            revert AlreadyClaimedReward();
        }
        uint256 currentPrice = getFeedValueOfAsset(oracleAddress);
        if (currentPrice >= priceAtInsurance) {
            revert NoChangeInAssetPrice();
        }
        uint256 totalAmount = getInsuranceAmount(currentPrice);
        if (totalAmount == 0) {
            revert InvalidClaimAmount();
        }
        uint256 maximumClaimableAmount = (totalAmount * plan) / 10;
        if (totalAmount < maximumClaimableAmount) {
            claimAmount = totalAmount;
        } else {
            claimAmount = maximumClaimableAmount;
        }
    }

    /////////////////////////
    // Public View //////////
    /////////////////////////

    /**
     * @dev Calculates the insurance amount based on the current asset price.
     * @param _currentPrice The current price of the asset.
     * @return The total insurance amount.
     */
    function getInsuranceAmount(uint256 _currentPrice) public view returns (uint256) {
        uint256 tokensHold = getTokenBalance(assetAddress, owner);
        uint256 claimableTokens;
        if (tokensHold < tokensInsured) {
            claimableTokens = tokensHold;
        } else {
            claimableTokens = tokensInsured;
        }
        return (((priceAtInsurance - _currentPrice) * claimableTokens) / 10 ** decimals);
    }

    /**
     * @dev Retrieves the claim amount state variable which would be claimed by the owner.
     * @return The claimamount.
     */
    function getClaimAmount() public view returns (uint256) {
        return claimAmount;
    }

    /**
     * @dev Checks if the insurance has been claimed.
     * @return True if the insurance has been claimed.
     */
    function isClaimed() public view returns (bool) {
        return claimed;
    }

    /////////////////////////
    // Internal View ///
    /////////////////////////

    /**
     * @dev Retrieves the token balance of an account for a given token address.
     * @param tokenAddress The address of the token.
     * @param accountAddress The address of the account.
     * @return The token balance.
     */
    function getTokenBalance(address tokenAddress, address accountAddress) internal view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(accountAddress);
    }

    /**
     * @dev Retrieves the latest feed value of an asset from the specified oracle address.
     * @param _oracleAddress The address of the price oracle contract.
     * @return The latest feed value.
     */
    function getFeedValueOfAsset(address _oracleAddress) internal view returns (uint256) {
        AggregatorV3Interface priceConsumer = AggregatorV3Interface(_oracleAddress);
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt */
            ,
            /*uint timeStamp */
            ,
            /*uint80 answeredInRound */
        ) = priceConsumer.latestRoundData();
        return uint256(price);
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
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.19;

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}