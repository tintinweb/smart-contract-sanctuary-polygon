// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ICampaignContract.sol";

contract CampaignContract is ICampaignContract, Ownable, Initializable {
    // Counter campaign id
    using Counters for Counters.Counter;

    address public vaultWallet;
    address private collectableCampaignsCreationWallet;
    address private userCollectableCampaign;

    Counters.Counter private _campCounter;

    constructor() initializer {}

    // Constructor
    function initialize() public payable initializer {
        vaultWallet = 0x1ee5B2BDaFb25769A3Fe0F0Fcc00E0C0035D598d;
    }

    // Mapping
    mapping(uint256 => string) private countToCampaignId; // Map counter to campaign
    mapping(string => Campaign) private idToCampaign; // Map campaignId to campaign
    mapping(string => mapping(address => SuperFan)) private fanToCamp; // Map campaignId to list fan
    mapping(string => string[]) private campaignToInvestor;


    modifier conditions(string memory _campaignId, uint _endTimestamp, uint256 _fractionCount){
        require(isDivisibleBy10(_fractionCount), "CampaignContract::createCampaign: You must set fraction divisible by 10");
        require(vaultWallet != address(0), "CampaignContract::createCampaign: You must set vault wallet first");
        require(_endTimestamp > block.timestamp, "CampaignContract::createCampaign: Campaign must end in the future");
        require(!isExisted(_campaignId), "CampaignContract::createCampaign:: Campaign is existed");
        _;
    }

    modifier validFund(string memory _campaignId, uint256 _amount) {
        require(isExisted(_campaignId), "CampaignContract::fundCampaign: Non existent campaign id provided");
        require(isCampaignActive(_campaignId), "CampaignContract::fundCampaign: Campaign not active");
        require(!isGoalReached(_campaignId),"CampaignContract::fundCampaign: Campaing is Goal Reached");
        require(_amount > 0, "CampaignContract::fundCampaign: You must send some amount fractions");
        _;
    }

    modifier validClaim(string memory _campaignId) {
        require(isGoalReached(_campaignId),"CampaignContract::fundCampaign: Campaing is not Goal Reached");
        _;
    }


    function isCompleted(string memory _campaignId) override internal  view returns(bool){
        return idToCampaign[_campaignId].completed;
    }


    function isExisted(string memory _campaignId) override internal  view returns(bool){
        return idToCampaign[_campaignId].fractionCount != 0;
    }

    function isGoalReached(string memory _campaignId) override internal view returns(bool) {
        return idToCampaign[_campaignId].goal;
    }

    function isCampaignActive(string memory _campaignId) override internal view returns(bool) {
        return idToCampaign[_campaignId].endDate > block.timestamp;
    }

    function setVaultWallet(address vault) override external onlyOwner {
        require(vault !=  address(0), "Vault wallet cannot be empty");
        vaultWallet = vault;
    }

    function setCollectableCampaignsCreationWallet(address _collectableCampaignsCreationWallet) override external {
        collectableCampaignsCreationWallet = _collectableCampaignsCreationWallet;
    }

    function setUserCollectableCampaign(address _userCollectableCampaign) override external{
        userCollectableCampaign = _userCollectableCampaign;
    }

    function createCampaign(
        string memory _campaignId, string memory _creator, uint256 _raise, CampaignType _campaignType, uint256 _startDate,
        uint256 _endDate, uint256 _fractionCount, uint256 _priceFraction
    ) override public onlyOwner conditions(_campaignId, _endDate, _fractionCount) {

        uint256 newCampCount = _campCounter.current();

        Campaign memory _camp = Campaign(
            _creator,
            _campaignId,
            _raise,
            0,
            _campaignType,
            _startDate,
            _endDate,
            _fractionCount,
            _fractionCount * 90 / 100, //10% Owned by SuperJoi
            _priceFraction,
            false,
            false
        );

        idToCampaign[_campaignId] = _camp;
        countToCampaignId[newCampCount] = _campaignId;
        _campCounter.increment();

        emit CreateCampaign(_campaignId,_camp);
    }

    function getCampaigns() override public view returns (Campaign[] memory) {
        uint256 currentCampId = _campCounter.current();
        Campaign[] memory listCamp = new Campaign[](currentCampId);
        for (uint i = 0; i < currentCampId; i++) {
            listCamp[i] = idToCampaign[countToCampaignId[i]];
        }

        return listCamp;
    }

    function getCampaign(string memory _campaignId) override public view returns (Campaign memory) {
        return idToCampaign[_campaignId];
    }

    function getInvestorDetail(string memory _campaignId, address _walletAddress) override public view returns (SuperFan memory) {

        return fanToCamp[_campaignId][_walletAddress];
    }

    function getInvestors(string memory _campaignId) override public view returns (string[] memory){
        string[] memory result = campaignToInvestor[_campaignId];
        return result;
    }

    function fundCampaign(string memory _campaignId, uint256 _fractionAmount, string memory _walletAddress) override public {
        Campaign storage campaign = idToCampaign[_campaignId];
        SuperFan storage superfan = fanToCamp[_campaignId][_msgSender()];
        campaignToInvestor[_campaignId].push(_walletAddress);

        require(_fractionAmount <= campaign.remainFractions, "Number of fragment must less than remain fragment.");

        uint256 payAmount = _fractionAmount * campaign.pricePerFraction;

        // Update campaign
        campaign.amount += payAmount;
        campaign.remainFractions -= _fractionAmount;

        // Add user to list fan
        superfan.fundedAmount += payAmount;
        superfan.numberOfFractions += _fractionAmount;

        emit FundCampaign(_walletAddress,_campaignId,_fractionAmount,payAmount);
        checkFinalPayment(campaign.remainFractions, _campaignId);
    }

    function doClaimCampaign(Campaign storage campaign) private {
        // Update campaign

        // Transfer token to vault wallet
        // uint256 amount = campaign.amount;
        // uint256 superJoiAmount = amount * 10 / 100;
        // uint256 ownerAmount = amount - superJoiAmount;

        // TODO: Transfer fragments token to fan

        emit ClaimCampaign(block.timestamp,campaign.amount,campaign.fractionCount - campaign.remainFractions);
    }

    function  claimCampaign(string memory campId) override public onlyOwner{
        require(vaultWallet != address(0), "You must set vault wallet first");

        Campaign storage campaign = idToCampaign[campId];
        require(!campaign.completed, "Executed");
        campaign.completed = true;
        require(campaign.endDate < block.timestamp, "This campaign is not ended.");
        // require(campaign.creator == msg.sender, "You are not owner of this campaign.");

        doClaimCampaign(campaign);        // require(campaign.creator == msg.sender, "You are not owner of this campaign.");


    }

    function setGoalReached(string memory _campaignId) override public onlyOwner{
        Campaign storage campaign = idToCampaign[_campaignId];
        require(campaign.endDate < block.timestamp, "This campaign is not ended.");
        campaign.goal = true;
    }


    function forceClaim(string memory campId) public onlyOwner {
        require(vaultWallet != address(0), "You must set vault wallet first");

        Campaign storage campaign = idToCampaign[campId];

        doClaimCampaign(campaign);
    }

    function checkFinalPayment(uint256 currentRemainFractions,string memory _campaignId) override internal{

        if(currentRemainFractions == 0){
            Campaign storage campaign = idToCampaign[_campaignId];

            campaign.goal = true;
            string[] memory investors  = campaignToInvestor[_campaignId];
            emit GoalReached(_campaignId, campaign, investors);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma abicoder v2;

abstract contract ICampaignContract {

    enum CampaignType {
        FLEX, //0
        FIX   //1
    }

    // Campaign
    struct Campaign {
        string creator;
        string campaignId;
        uint256 raise;
        uint256 amount;
        CampaignType campaignType;
        uint256 startDate;
        uint256 endDate;
        uint256 fractionCount;
        uint256 remainFractions;
        uint256 pricePerFraction;
        // address cryptocurrency;
        bool completed;
        bool goal;
    }

    event ClaimCampaign(
        uint256 claimedAt,
        uint256 claimedAmount,
        uint256 claimedFractions
    );

    // Fan info
    struct SuperFan {
        uint256 fundedAmount;
        uint256 numberOfFractions;
    }

    // Events
    event FundCampaign(string fanAddress, string campaignId, uint256 fractionAmount, uint256 fundedAmount);
    event CreateCampaign(string campaignId, Campaign campaign);
    event GoalReached(string campaignId, Campaign campaign, string[] investor);

    function setVaultWallet(address vaultAddress) external virtual;

    function isDivisibleBy10(uint256 _fractionCount) internal pure returns (bool){
        return (_fractionCount > 0) && (_fractionCount % 10 == 0);
    }

    function isCompleted(string memory _campaignId) internal virtual view returns (bool);

    function isExisted(string memory _campaignId) internal virtual view returns (bool);

    function isGoalReached(string memory _campaignId) internal virtual view returns (bool);

    function isCampaignActive(string memory _campaignId) internal virtual view returns (bool);

    function checkFinalPayment(uint256 _currentRemainFractions, string memory _campaignId) internal virtual;

    function getCampaign(string memory _campaignId) external virtual view returns (Campaign memory);

    function getInvestors(string memory _campaignId) external virtual view returns (string[] memory);

    function getInvestorDetail(string memory _campaignId, address _walletAddress) external virtual view returns (SuperFan memory);

    function getCampaigns() external virtual view returns (Campaign[] memory);

    function createCampaign(string memory _campaignId, string memory _creator, uint256 _raise, CampaignType _campaignType, uint256 _startDate, uint256 _endDate,
        uint256 _fractionCount, uint256 _priceFraction) external virtual;

    function claimCampaign(string memory _campaignId) external virtual;

    function fundCampaign(string memory _campaignId, uint256 _fractionAmount, string memory walletAddress) external virtual;

    function setGoalReached(string memory _campaignId) external virtual;

    function setCollectableCampaignsCreationWallet(address _collectableCampaignsCreationWallet) external virtual;

    function setUserCollectableCampaign(address _userCollectableCampaign) external virtual;
    // function finalPayment(string memory _campaignId) external payable;
    // function getRefund(string memory _campaignId) external payable;

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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