/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: @openzeppelin/contracts/utils/Address.sol

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
  function owner() external view  returns (address);
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface Aggregator {
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

contract TechNa is ReentrancyGuard, Ownable {
    address public Owner;
    uint256 public phaseId;
    uint256 public USDT_MULTIPLIER;
    uint256 public ETH_MULTIPLIER;
    address public fundReceiver;
    bool public referralEnable;
    address public SaleToken;
    address[] public uniqueReferrals;
    uint256 public referralPercentage;
    uint256 internal referralPercentDivider;
    uint256 internal referralLength;

    struct Presale {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 tokensToSell;
        uint256 saleProgress;
        uint256 thisPhaseToken;
        uint256 sold;
        bool Active;
    }

    struct ClaimData {
        uint256 investedAmount;
        uint256 claimedAmount;
        address[] referral;
        bool isBuy;
    }

    IERC20Metadata public USDT;
    IERC20Metadata public Ether;
    IERC20Metadata public BNB;
    IERC20Metadata public BUSD;
    IERC20Metadata public USDC;
    Aggregator internal aggregatorInterfaceETH;
    Aggregator internal aggregatorInterfaceBNB;
    Aggregator internal aggregatorInterfaceMATIC;
    Aggregator internal aggregatorInterfaceUSDC;
    Aggregator internal aggregatorInterfaceBUSD;
    // https://docs.chain.link/docs/ethereum-addresses/ => (ETH / USD)

    mapping(uint256 => bool) public paused;
    mapping(uint256 => Presale) public presale;
    mapping(address => mapping(uint256 => ClaimData)) public userData;
    mapping(address => bool) public isExcludeMinToken;
    mapping(address => bool) public referralExist;

    event PresaleCreated(
        uint256 indexed _id,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime
    );

    event PresaleUpdated(
        bytes32 indexed key,
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    event TokensBought(
        address indexed user,
        uint256 indexed id,
        address indexed purchaseToken,
        uint256 tokensBought,
        uint256 amountPaid,
        uint256 timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint256 indexed id,
        uint256 amount,
        uint256 timestamp
    );

    event PresaleTokenAddressUpdated(
        address indexed prevValue,
        address indexed newValue,
        uint256 timestamp
    );

    event PresalePaused(uint256 indexed id, uint256 timestamp);
    event PresaleUnpaused(uint256 indexed id, uint256 timestamp);

    constructor( address _saleTokenAddress) {
        aggregatorInterfaceETH = Aggregator(
            0xF9680D99D6C9589e2a93a78A04A279e509205945    //Mainnet
        );
        aggregatorInterfaceBNB = Aggregator(
            0x82a6c4AF830caa6c97bb504425f6A66165C2c26e    //Mainnet
        );
        aggregatorInterfaceMATIC = Aggregator(
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0    //Mainnet
        );
        aggregatorInterfaceUSDC = Aggregator(
            0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7    //Mainnet
        );
        aggregatorInterfaceBUSD = Aggregator(
            0xE0dC07D5ED74741CeeDA61284eE56a2A0f7A4Cc9    //Mainnet
        );

        SaleToken = _saleTokenAddress;
        USDT = IERC20Metadata(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);   //Mainnet
        Ether = IERC20Metadata(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);  //Mainnet
        BNB = IERC20Metadata(0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3);    //Mainnet

        USDC = IERC20Metadata(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);   //Mainnet

        BUSD = IERC20Metadata(0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7);   //Mainnet
        ETH_MULTIPLIER = (10**20);
        USDT_MULTIPLIER = (10**6);
        referralPercentage = 30;
        referralPercentDivider = 1000;
        referralLength = 5;
        fundReceiver = 0x228e550f6Dd21dA8a669506B4Bb9cBc612BEDF04 ;
        referralEnable = true;
        Owner=  0x228e550f6Dd21dA8a669506B4Bb9cBc612BEDF04 ;
    }

    // /**
    //  * @dev Creates a new presale
    //  * @param _price Per token price multiplied by (10**18)
    //  * @param _tokensToSell No of tokens to sell
    //  */
    function createPresalePhase(uint256 _price, uint256 _tokensToSell)
        external
        onlyOwner
    {
        require(_price > 0, "Zero price");
        require(_tokensToSell > 0, "Zero tokens to sell");
        require(presale[phaseId].Active == false, "Previous Sale is Active");

        phaseId++;

        presale[phaseId] = Presale(
            0,
            0,
            _price,
            _tokensToSell,
            0,
            _tokensToSell,
            0,
            false
        );
        userData[msg.sender][phaseId].isBuy = true;
        emit PresaleCreated(phaseId, _tokensToSell, 0, 0);
    }

    function startPresalePhase() public onlyOwner {
        presale[phaseId].startTime = block.timestamp;
        presale[phaseId].Active = true;
    }

    function endPresalePhase() public onlyOwner {
        require(
            presale[phaseId].Active = true,
            "This presale is already Inactive"
        );
        presale[phaseId].endTime = block.timestamp;
        presale[phaseId].Active = false;
    }

    // /**
    //  * @dev Update a new presale
    //  * @param _price Per USD price should be multiplied with token decimals
    //  * @param _tokensToSell No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
    //  */
    function updatephase(
        uint256 _id,
        uint256 _price,
        uint256 _tokensToSell
    ) external checkPhaseId(_id) onlyOwner {
        require(_price > 0, "Zero price");
        require(_tokensToSell > 0, "Zero tokens to sell");
        presale[_id].price = _price;
        presale[_id].tokensToSell = _tokensToSell;
         presale[phaseId].thisPhaseToken=_tokensToSell;

    }

    /**
     * @dev To pause the presale
     * @param _id Presale id to update
     */
    function pausePresale(uint256 _id) external checkPhaseId(_id) onlyOwner {
        require(!paused[_id], "Already paused");
        paused[_id] = true;
        emit PresalePaused(_id, block.timestamp);
    }

    /**
     * @dev To unpause the presale
     * @param _id Presale id to update
     */
    function unPausePresale(uint256 _id) external checkPhaseId(_id) onlyOwner {
        require(paused[_id], "Not paused");
        paused[_id] = false;
        emit PresaleUnpaused(_id, block.timestamp);
    }

    /**
     * @dev To get latest ethereum price in 10**18 format
     */
    function getLatestPriceEth() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterfaceETH.latestRoundData();
        price = price;
        return uint256(price);
    }

    function getLatestPriceBnb() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterfaceBNB.latestRoundData();
        price = price;
        return uint256(price);
    }

    function getLatestPriceMatic() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterfaceMATIC.latestRoundData();
        price = price;
        return uint256(price);
    }

    function getLatestPriceUsdc() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterfaceUSDC.latestRoundData();
        price = price;
        return uint256(price);
    }

    function getLatestPriceBusd() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterfaceBUSD.latestRoundData();
        price = price;
        return uint256(price);
    }

    modifier checkPhaseId(uint256 _id) {
        require(_id > 0 && _id <= phaseId, "Invalid presale id");
        _;
    }

    modifier checkSaleState(uint256 _id, uint256 amount) {
        require(
            block.timestamp >= presale[_id].startTime &&
                presale[_id].Active == true,
            "Invalid time for buying"
        );
        require(
            amount > 0 && amount <= presale[_id].tokensToSell,
            "token greater then tokenToSell in this phase"
        );
        _;
    }


    function buyToken(
        address currencyAddress,
        uint256 _enterAmount,
        address _referral
    ) external checkPhaseId(phaseId) returns (bool) {
        require(
            currencyAddress == address(USDT) ||
                currencyAddress == address(Ether) ||
                currencyAddress == address(BNB) ||
                currencyAddress == address(USDC) ||
                currencyAddress == address(BUSD),
            "Invalid Currency Address"
        );
        require(_referral != msg.sender ,"You cannot refer yourself");
        require(!paused[phaseId], "Presale paused");
        require(presale[phaseId].Active == true, "Presale is not active yet");
        uint256 tokens;
        if (currencyAddress == address(USDT)) {
            uint256 _tokens = usdtToTokens(phaseId, _enterAmount);
            tokens = _tokens;
        } else if (currencyAddress == address(Ether)) {
            uint256 _tokens = ethToTokens(phaseId, _enterAmount);
            tokens = _tokens;
        } else if (currencyAddress == address(BNB)) {
            uint256 _tokens = bnbToTokens(phaseId, _enterAmount);
            tokens = _tokens;
        } else if (currencyAddress == address(USDC)) {
            uint256 _tokens = USDCToTokens(phaseId, _enterAmount);
            tokens = _tokens;
        } else {
            uint256 _tokens = BUSDToTokens(phaseId, _enterAmount);
            tokens = _tokens;
        }

        require(
            tokens > 0 && tokens <= presale[phaseId].tokensToSell,
            "token less or greater then tokenToSell in this phase"
        );

        uint256 referralAmount = (tokens * referralPercentage) /
            referralPercentDivider;
        if (
            referralEnable == true && _referral != address(0) &&
            (userData[_referral][phaseId].isBuy == true )
        ) {
            if (
                userData[msg.sender][phaseId].referral.length <= referralLength
            ) {
                IERC20(SaleToken).transferFrom(Owner,_referral, referralAmount);
                userData[msg.sender][phaseId].referral.push(_referral);
                if (referralExist[_referral] == false) {
                    uniqueReferrals.push(_referral);
                    referralExist[_referral] = true;
                }
            }
        }
        
        presale[phaseId].sold += tokens;
        presale[phaseId].tokensToSell -= tokens;
        uint256 amountInUsdt= tokenToUsdt(phaseId,tokens);
        userData[msg.sender][phaseId].investedAmount += amountInUsdt;
        userData[msg.sender][phaseId].claimedAmount += tokens;
        userData[msg.sender][phaseId].isBuy = true;
     presale[phaseId].saleProgress =
            (presale[phaseId].sold * referralPercentDivider * 100) /
            presale[phaseId].thisPhaseToken;
        (bool success, ) = address(currencyAddress).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                fundReceiver,
                _enterAmount
            )
        );
        require(success, "Token payment failed");
        IERC20(SaleToken).transferFrom(Owner,msg.sender, tokens);

        emit TokensBought(
            _msgSender(),
            phaseId,
            address(USDT),
            tokens,
            _enterAmount,
            block.timestamp
        );
        return true;
    }

    function buyWithMatic(address _referral)
        external
        payable
        checkPhaseId(phaseId)
        checkSaleState(phaseId, maticToTokens(phaseId, msg.value))
        nonReentrant
        returns (bool)
    {
        uint256 usdtAmount = (msg.value * getLatestPriceMatic()) /
            ETH_MULTIPLIER;
       require(_referral != msg.sender ,"You cannot refer yourself");
        require(!paused[phaseId], "Presale paused");
        require(presale[phaseId].Active == true, "Presale is not active yet");

        uint256 tokens = usdtToTokens(phaseId, usdtAmount);
        presale[phaseId].sold += tokens;
        presale[phaseId].tokensToSell -= tokens;
        presale[phaseId].saleProgress =
            (presale[phaseId].sold * referralPercentDivider * 100) /
            presale[phaseId].thisPhaseToken;
        uint256 referralAmount = (tokens * referralPercentage) /
            referralPercentDivider;
        if (
            referralEnable == true && _referral != address(0) &&
            (userData[_referral][phaseId].isBuy == true )
        ) {
            if (
                userData[msg.sender][phaseId].referral.length < referralLength
            ) {
                IERC20(SaleToken).transferFrom(Owner,_referral, referralAmount);
                userData[msg.sender][phaseId].referral.push(_referral);
                if (referralExist[_referral] == false) {
                    uniqueReferrals.push(_referral);
                    referralExist[_referral] = true;
                }
            }
        }
        userData[msg.sender][phaseId].investedAmount += usdtAmount;
        userData[msg.sender][phaseId].claimedAmount += tokens;
        userData[msg.sender][phaseId].isBuy = true;

        payable(fundReceiver).transfer(msg.value);
        IERC20(SaleToken).transferFrom(Owner,msg.sender, tokens);
        emit TokensBought(
            _msgSender(),
            phaseId,
            address(0),
            tokens,
            msg.value,
            block.timestamp
        );
        return true;
    }
  
      //----------------------> All currencyToDollar Helper functions

       function ethToUsdt(uint256 amount)
        public
        view
        returns (uint256 usdtAmount)
    {
         usdtAmount = (amount * getLatestPriceEth()) / ETH_MULTIPLIER;
    }
     function bnbToUsdt( uint256 amount)
        public
        view
        returns (uint256 usdtAmount)
    {
         usdtAmount = (amount * getLatestPriceBnb()) / ETH_MULTIPLIER;
        
    }

        function BUSDToUsdt( uint256 amount)
        public
        view
        returns (uint256 usdtAmount)
    {
         usdtAmount = (amount * getLatestPriceBusd()) / ETH_MULTIPLIER;
       
    }
    function USDCToUsdt( uint256 amount)
        public
        view
        returns (uint256 usdtAmount)
    {
         usdtAmount = (amount * getLatestPriceUsdc()) / 1e8;
    }
       function maticToUsdt(uint256 amount)
        public
        view
        returns (uint256 usdtAmount)
    {
         usdtAmount = (amount * getLatestPriceMatic()) / ETH_MULTIPLIER;
    }

     // ------------->  All currencyToToken helper functions

    function ethToTokens(uint256 _id, uint256 amount)
        public
        view
        returns (uint256 _tokens)
    {
        uint256 usdtAmount = (amount * getLatestPriceEth()) / ETH_MULTIPLIER;
        _tokens = usdtToTokens(_id, usdtAmount);
    }

    function bnbToTokens(uint256 _id, uint256 amount)
        public
        view
        returns (uint256 _tokens)
    {
        uint256 usdtAmount = (amount * getLatestPriceBnb()) / ETH_MULTIPLIER;
        _tokens = usdtToTokens(_id, usdtAmount);
    }

    function maticToTokens(uint256 _id, uint256 amount)
        public
        view
        returns (uint256 _tokens)
    {
        uint256 usdtAmount = (amount * getLatestPriceMatic()) / ETH_MULTIPLIER;
        _tokens = usdtToTokens(_id, usdtAmount);
    }

    function USDCToTokens(uint256 _id, uint256 amount)
        public
        view
        returns (uint256 _tokens)
    {
        uint256 usdtAmount = (amount * getLatestPriceUsdc()) / 1e8;
        _tokens = usdtToTokens(_id, usdtAmount);
    }

    function BUSDToTokens(uint256 _id, uint256 amount)
        public
        view
        returns (uint256 _tokens)
    {
        uint256 usdtAmount = (amount * getLatestPriceBusd()) / ETH_MULTIPLIER;
        _tokens = usdtToTokens(_id, usdtAmount);
    }

    /**
     * @dev Helper funtion to get tokens for given usdt amount
     * @param _id Presale id
     * @param amount No of usdt
     */
    function usdtToTokens(uint256 _id, uint256 amount)
        public
        view
        checkPhaseId(_id)
        returns (uint256 _tokens)
    {
        _tokens = (amount * presale[_id].price) / USDT_MULTIPLIER;
    }

    function tokenToUsdt(uint256 _id, uint256 amount)
        internal
        view
        checkPhaseId(_id)
        returns (uint256 _usdt)
    {

        _usdt= (amount * USDT_MULTIPLIER) / presale[_id].price;
    }

    function WithdrawTokens(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(fundReceiver, amount);
    }

    function WithdrawContractFunds(uint256 amount) external onlyOwner {
        payable(fundReceiver).transfer(amount);
    }

    function changeFundWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Invalid parameters");
        fundReceiver = _wallet;
    }


    function setReferrelStatus(bool _status) external onlyOwner {
        referralEnable = _status;
    }

    function changeUSDTToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero token address");
        USDT = IERC20Metadata(_newAddress);
    }

    function changeEtherToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero token address");
        Ether = IERC20Metadata(_newAddress);
    }

    function changeBNBToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero token address");
        BNB = IERC20Metadata(_newAddress);
    }

    function changeUSDCToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero token address");
        USDC = IERC20Metadata(_newAddress);
    }

    function changeBUSDToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero token address");
        BUSD = IERC20Metadata(_newAddress);
    }

    function changeSaleToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero token address");
        SaleToken = _newAddress;
    }

    function changeReferralPercentage(uint256 _newPercentage)
        external
        onlyOwner
    {
        referralPercentage = _newPercentage;
    }

    function changeReferralLength(uint256 _length) external onlyOwner {
        referralLength = _length;
    }

    function saleProgress() public view returns (uint256) {
        return (presale[phaseId].saleProgress);
    }
}