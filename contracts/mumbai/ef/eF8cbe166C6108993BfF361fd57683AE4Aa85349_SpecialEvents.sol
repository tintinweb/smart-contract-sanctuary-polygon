// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/ILandRegistry.sol";
import "./interfaces/IConversion.sol";

error OnlyManager();
error Maintenance();
error ZeroAddress();
error OnlyExecutor();
error EventExisted();
error NotSupported();
error InvalidRequest();
error OnlyAuthorizer();
error LengthMismatch();
error InvalidSetting();
error NotInWhitelist();
error NotStartOrEnded();
error InvalidSignature();
error ExceedAllocation();
error PaymentNotSupported();
error InvalidPaymentAmount();

contract SpecialEvents {
    using SafeERC20 for IERC20;

    struct EventInfo {
        uint256 eventType;
        uint256 start;
        uint256 end;
        uint256 maxAllocation;
        uint256 availableAmount;
        uint256 maxSaleAmount;
        string description;
    }

    struct Receipt {
        uint256 eventId;
        uint256 dateOfIssue;
        uint256 tokenId;
        address nftToken;
        address operator;
        address beneficiary;
        address paymentToken;
        uint256 paymentAmount;
        string eventType;           //  "Fulfillment", "Purchase", or "Air Drop"
        string exReceipt;           //   external receipt when `eventType = Fulfillment`, Others = N/A
    }
    
    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 private constant AUTHORIZER_ROLE = keccak256("AUTHORIZER_ROLE");
    bytes32 private constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 private constant PURCHASE_TYPE_HASH = keccak256("uint256,address,uint256,int256[],int256[],bytes");

    IGovernance public gov;
    ILandRegistry public land;
    ICoversion public conversion;

    //  Whitelist of coordinates that is available to be purchased
    //  longitude -> latitude -> city
    mapping(int256 => mapping(int256 => string)) public coordinates;

    //  eventId -> EventInfo
    mapping(uint256 => EventInfo) public events;
    
    //  city -> eventId
    mapping(bytes32 => uint256) public eventByCity;

    //  record amount of purchased items per event (eventId -> account -> purchased_amount)
    mapping(uint256 => mapping(address => uint256)) public purchased;

    //  record a whitelist of account per event (eventId -> account -> allowable/unallowable)
    mapping(uint256 => mapping(address => bool)) public whitelist;

    //  record a payment price for each type of tokens per event (eventId -> token -> price)
    mapping(uint256 => mapping(address => uint256)) public prices;

    //  record activities (longitude -> latitude -> a list of Receipt)
    mapping(int256 => mapping(int256 => Receipt[])) private receipts;

    event Purchased(
        uint256 indexed eventId,
        address indexed to,
        address indexed token,
        uint256 purchasedAmt,
        uint256 paymentAmt,
        int256[] longitudes,
        int256[] latitudes,
        uint256[] tokenIds,
        string[] uris
    );

    event Fulfillment(
        uint256 indexed eventId,
        address indexed operator,
        address indexed to,
        int256[] longitudes,
        int256[] latitudes,
        uint256[] tokenIds,
        string[] uris,
        string receipt
    );

    event AirDrop(
        uint256 eventId,
        address operator,
        address[] beneficiaries,
        int256[] longitudes,
        int256[] latitudes,
        uint256[] tokenIds,
        string[] uris
    );

    event SetPrice(
        uint256 indexed eventId,
        address indexed token,
        uint256 indexed price
    );

    event SetEvent(
        uint256 indexed eventId,
        uint256 indexed eventType,
        uint256 start,
        uint256 end,
        uint256 maxSaleAmount,
        uint256 maxAllocation,
        string[] cities,
        string description
    );

    event SetLandAvailability(
        string city,
        int256[] longitudes,
        int256[] latitudes,
        bool opt
    );

    event SetWhitelist(
        uint256 indexed eventId,
        address[] beneficiaries,
        bool opt
    );

    modifier onlyManager() {
        //  Note: Setting management should not allow metatransaction
        if (!gov.hasRole(MANAGER_ROLE, msg.sender)) revert OnlyManager();
        _;
    }

    modifier onlyAuthorizer() {
        //  Note: Setting management should not allow metatransaction
        if (!gov.hasRole(AUTHORIZER_ROLE, msg.sender)) revert OnlyAuthorizer();
        _;
    }

    modifier onlyExecutor() {
        //  Note: Setting management should not allow metatransaction
        if (!gov.hasRole(EXECUTOR_ROLE, msg.sender)) revert OnlyExecutor();
        _;
    }

    constructor(IGovernance _gov, ILandRegistry _land, ICoversion _conversion) {
        gov = _gov;
        land = _land;
        conversion = _conversion;
    }

    /**
        @notice Update a new address of Governance contract
        @dev  Caller must have MANAGER_ROLE
        @param _newGov         Address of new Governance contract
        Note: if `_newGov == 0x00`, this contract is deprecated
    */
    function setGovernance(IGovernance _newGov) external onlyManager {
        gov = _newGov;
    }

    /**
        @notice Update a new address of LandRegistry contract
        @dev  Caller must have MANAGER_ROLE
        @param _newLandRegistry         Address of new LandRegsitry contract
    */
    function setLandRegistry(ILandRegistry _newLandRegistry) external onlyManager {
        if (address(_newLandRegistry) == address(0)) revert ZeroAddress();

        land = _newLandRegistry;
    }

    /**
        @notice Update a new address of Conversion contract
        @dev  Caller must have MANAGER_ROLE
        @param _newConversion         Address of new Conversion contract
    */
    function setConversion(ICoversion _newConversion) external onlyManager {
        if (address(_newConversion) == address(0)) revert ZeroAddress();

        conversion = _newConversion;
    }

    /**
        @notice Set fixed price (of one payment token) in the `_eventId`
        @dev  Caller must have MANAGER_ROLE
        @param _eventId            Number id of an event
        @param _token              Address of payment token (0x00 for native coin)
        @param _price              Amount to pay in the `_eventId` (if choosing `_token` as payment token)
    */
    function setPrice(uint256 _eventId, address _token, uint256 _price) external onlyManager {
        //  `_eventId` not existed -> endTime = 0 -> revert
        //  `_eventId` already ended -> revert
        uint256 _current = block.timestamp;
        uint256 _endTime = events[_eventId].end;
        if (_endTime == 0 || _current >= _endTime) revert InvalidSetting();
        if (!gov.paymentToken(_token)) revert PaymentNotSupported();

        prices[_eventId][_token] = _price;

        emit SetPrice(_eventId, _token, _price);
    }

    /**
        @notice Add/Remove `_tokenId` of lands to be for sale
        @dev  Caller must have MANAGER_ROLE
        @param _longitudes          A list of `_longitude` values
        @param _latitudes           A list of `_latitude` values
        @param _setOpt              Setting option (true = add, false = remove)
    */
    function setAvailableLands(
        string calldata _city,
        int256[] calldata _longitudes,
        int256[] calldata _latitudes,
        bool _setOpt
    ) external onlyManager {
        uint256 _len = _longitudes.length;
        if (_latitudes.length != _len) revert LengthMismatch();

        if (_setOpt){
            for(uint256 i; i < _len; i++)
                coordinates[_longitudes[i]][_latitudes[i]] = _city;
        }
        else {
            for(uint256 i; i < _len; i++)
                delete coordinates[_longitudes[i]][_latitudes[i]];
        }  

        emit SetLandAvailability(_city, _longitudes, _latitudes, _setOpt);
    }

    /**
        @notice Set a configuration of one `_eventId`
        @dev  Caller must have MANAGER_ROLE
        @param _eventType           Type of an event (AirDrop = 1, Sale = Non-zero)
        @param _eventId             Number id of an event
        @param _start               Starting time of `_eventId`
        @param _end                 Ending time of `_eventId`
        @param _maxAllocation       Max number of land items can be purchased in the `_eventId` per account
        @param _maxSaleAmount       Max number of land items can be purchased in the `_eventId`
        @param _description         Event Description
    */
    function setEvent(
        uint256 _eventType,
        uint256 _eventId,
        uint256 _start,
        uint256 _end,
        uint256 _maxAllocation,
        uint256 _maxSaleAmount,
        string[] calldata _cities,
        string calldata _description
    ) external onlyManager {
        uint256 _current = block.timestamp;
        if (events[_eventId].end != 0) revert EventExisted();
        if (_start >= _end || _current >= _end || _current > _start || _eventType == 0) revert InvalidSetting();

        events[_eventId].eventType = _eventType;
        events[_eventId].start = _start;
        events[_eventId].end = _end;
        events[_eventId].maxAllocation = _maxAllocation;
        events[_eventId].maxSaleAmount = _maxSaleAmount;
        events[_eventId].availableAmount = _maxSaleAmount;
        events[_eventId].description = _description;

        uint256 _len = _cities.length;
        for (uint256 i; i < _len; i++)
            eventByCity[keccak256(bytes(_cities[i]))] = _eventId;

        emit SetEvent(_eventId, _eventType, _start, _end, _maxSaleAmount, _maxAllocation, _cities, _description);
    }

    /**
        @notice Add/Remove `_beneficiaries`
        @dev  Caller must have MANAGER_ROLE
        @param _eventId                     Number id of an event
        @param _beneficiaries               A list of `_beneficiaries`
        @param _opt                         Option choice (true = add, false = remove)
    */
    function setWhitelist(uint256 _eventId, address[] calldata _beneficiaries, bool _opt) external onlyManager {
        uint256 _current = block.timestamp;
        uint256 _endTime = events[_eventId].end;
        if (_endTime == 0 || _current >= _endTime) revert InvalidSetting();

        uint256 _len = _beneficiaries.length;
        for(uint256 i; i < _len; i++) {
            if (_opt)
                whitelist[_eventId][_beneficiaries[i]] = true;
            else 
                delete whitelist[_eventId][_beneficiaries[i]];
        }

        emit SetWhitelist(_eventId, _beneficiaries, _opt);
    }

    /**
        @notice Complete a process of purchasing NFT items using credit/debit card
        @dev  Caller must have AUTHORIZER_ROLE
        @param _beneficiary         Address of Beneficiary to receive NFT items
        @param _longitudes          A list of `_longitude` values
        @param _latitudes           A list of `_latitude` values
        @param _uris                A list of `_tokenURIs` that match to each of `_tokenIds` respectively
        @param _receipt             Payment receipt

        Note: 
        - When `locked = true` is set in the Governance contract, 
            the `LandRegistry` will be disable operations that relate to transferring (i.e., transfer, mint, burn)
            Thus, it's not neccessary to add a modifier `isLocked()` to this function
        - fulfillment() and purchase() can share the same `eventId` since there are two acceptable payments - Credit/Debit and Crypto
        - For the AirDrop, it should be executed separately. Thus, it requires a unique `eventId` (not shared)
    */
    function fulfillment(
        address _beneficiary,
        int256[] memory _longitudes,
        int256[] memory _latitudes,
        string[] memory _uris,
        string memory _receipt
    ) external onlyAuthorizer {
        (uint256 _amount, uint256 _eventId) = _precheck(_longitudes, _latitudes, _uris);
        if (events[_eventId].eventType == 1) revert InvalidRequest();
        _isWhitelisted(_eventId, _beneficiary);

        uint256 _purchaseAmt = purchased[_eventId][_beneficiary] + _amount;
        if (_purchaseAmt > events[_eventId].maxAllocation) revert ExceedAllocation();

        events[_eventId].availableAmount -= _amount;         //  if `availableAmount` < `_amount` -> underflow -> revert
        purchased[_eventId][_beneficiary] = _purchaseAmt;

        uint256[] memory _tokenIds = _getTokenIds(_longitudes, _latitudes);
        land.assignParcels(_beneficiary, _tokenIds, _uris);

        uint256 _currentTime = block.timestamp;
        address _nftToken = address(land);
        for (uint256 i; i < _amount; i++) {
            receipts[_longitudes[i]][_latitudes[i]].push(
                Receipt({
                    eventId: _eventId,
                    dateOfIssue: _currentTime,
                    tokenId: _tokenIds[i],
                    nftToken: _nftToken,
                    operator: msg.sender,
                    beneficiary: _beneficiary,
                    paymentToken: address(1),
                    paymentAmount: 0,
                    eventType: "Fulfillment",
                    exReceipt: _receipt
                })
            );
        }

        emit Fulfillment(_eventId, msg.sender, _beneficiary, _longitudes, _latitudes, _tokenIds, _uris, _receipt);
    }

    /**
        @notice Purchase NFT Land Sale of a specific `eventId`
        @dev  Caller must be in the whitelist of `eventId`
        @param _paymentToken            Address of payment token (0x00 - Native Coin)
        @param _longitudes              A list of `_longitude` values
        @param _latitudes               A list of `_latitude` values
        @param _uris                    A list of `_tokenURIs` that match to each of `_tokenIds` respectively

        Note: 
        - When `locked = true` is set in the Governance contract, 
            the `LandRegistry` will be disable operations that relate to transferring (i.e., transfer, mint, burn)
            Thus, it's not neccessary to add a modifier `isLocked()` to this function
        - fulfillment() and purchase() can share the same `eventId` since there are two acceptable payments - Credit/Debit and Crypto
        - For the AirDrop, it should be executed separately. Thus, it requires a unique `eventId` (not shared)
    */
    function purchase(
        address _paymentToken,
        int256[] memory _longitudes,
        int256[] memory _latitudes,
        string[] memory _uris
    ) external payable {
        (uint256 _amount, uint256 _eventId) = _precheck(_longitudes, _latitudes, _uris);
        if (events[_eventId].eventType == 1) revert InvalidRequest();
        _isWhitelisted(_eventId, msg.sender);

        uint256 _purchaseAmt;
        uint256 _paymentAmt;
        uint256[] memory _tokenIds;
        {
            uint256 _price = prices[_eventId][_paymentToken];
            if (_price == 0) revert PaymentNotSupported();

            //  if `purchasedAmt + amount` exceeds `maxAllocation` -> revert
            //  if `paymentToken` = 0x00 (native coin), check `msg.value = price * amount`
            _purchaseAmt = purchased[_eventId][msg.sender] + _amount;
            _paymentAmt = _price * _amount;
            if (_purchaseAmt > events[_eventId].maxAllocation) revert ExceedAllocation();
            if (_paymentToken == address(0) && msg.value != _paymentAmt) revert InvalidPaymentAmount();
            events[_eventId].availableAmount -= _amount;         //  if `availableAmount` < `_amount` -> underflow -> revert
            
            purchased[_eventId][msg.sender] = _purchaseAmt;
            _makePayment(_paymentToken, msg.sender, _paymentAmt);

            _tokenIds = _getTokenIds(_longitudes, _latitudes);
            land.assignParcels(msg.sender, _tokenIds, _uris);

            uint256 _currentTime = block.timestamp;
            address _nftToken = address(land);
            for (uint256 i; i < _amount; i++) {
                receipts[_longitudes[i]][_latitudes[i]].push(
                    Receipt({
                        eventId: _eventId,
                        dateOfIssue: _currentTime,
                        tokenId: _tokenIds[i],
                        nftToken: _nftToken,
                        operator: msg.sender,
                        beneficiary: msg.sender,
                        paymentToken: _paymentToken,
                        paymentAmount: _price,
                        eventType: "Purchase",
                        exReceipt: "N/A"
                    })
                );
            }
        }
            
        emit Purchased(
            _eventId, msg.sender, _paymentToken, _amount, _paymentAmt, _longitudes, _latitudes, _tokenIds, _uris
        );
    }

    /**
        @notice Airdrop NFT items to `_beneficiaries`
        @dev  Caller must have MANAGER_ROLE
        @param _beneficiaries           A list of Beneficiaries to receive items
        @param _longitudes              A list of `_longitude` values
        @param _latitudes               A list of `_latitude` values
        @param _uris                    A list of `_tokenURIs` that match to each of `_tokenIds` respectively

        Note: 
        - When `locked = true` is set in the Governance contract, 
            the `LandRegistry` will be disable operations that relate to transferring (i.e., transfer, mint, burn)
            Thus, it's not neccessary to add a modifier `isLocked()` to this function
        - fulfillment() and purchase() can share the same `eventId` since there are two acceptable payments - Credit/Debit and Crypto
        - For the AirDrop, it should be executed separately. Thus, it requires a unique `eventId` (not shared)
    */
    function airdrop(
        address[] memory _beneficiaries,
        int256[] memory _longitudes,
        int256[] memory _latitudes,
        string[] memory _uris
    ) external onlyExecutor {
        if (_longitudes.length != _beneficiaries.length) revert LengthMismatch();
        (uint256 _amount, uint256 _eventId) = _precheck(_longitudes, _latitudes, _uris);
        if (events[_eventId].eventType != 1) revert InvalidRequest();

        uint256 _receiveAmt;
        for (uint256 i; i < _amount; i++) {
            _isWhitelisted(_eventId, _beneficiaries[i]);

            _receiveAmt = purchased[_eventId][_beneficiaries[i]] + 1;               
            if (_receiveAmt > events[_eventId].maxAllocation) revert ExceedAllocation();

            purchased[_eventId][_beneficiaries[i]] = _receiveAmt;
        }
        events[_eventId].availableAmount -= _amount;            //  if `availableAmount` < `_amount` -> underflow -> revert

        //  There's a case that a failure might occur
        //  - Beneficiary is a contract, but not implement IERC721Holder
        uint256[] memory _tokenIds = _getTokenIds(_longitudes, _latitudes);
        land.assignBatchParcels(_beneficiaries, _tokenIds, _uris);

        uint256 _currentTime = block.timestamp;
        address _nftToken = address(land);
        for (uint256 i; i < _amount; i++) {
            receipts[_longitudes[i]][_latitudes[i]].push(
                Receipt({
                    eventId: _eventId,
                    dateOfIssue: _currentTime,
                    tokenId: _tokenIds[i],
                    nftToken: _nftToken,
                    operator: msg.sender,
                    beneficiary: _beneficiaries[i],
                    paymentToken: address(1),
                    paymentAmount: 0,
                    eventType: "Air Drop",
                    exReceipt: "N/A"
                })
            );
        }

        emit AirDrop(_eventId, msg.sender, _beneficiaries, _longitudes, _latitudes, _tokenIds, _uris);
    }

    function _getTokenIds(int256[] memory _longitudes, int256[] memory _latitudes) private returns (uint256[] memory _tokenIds) {
        uint256 _len = _longitudes.length;
        _tokenIds = new uint256[](_len);
        for (uint256 i; i < _len; i++) 
            delete coordinates[_longitudes[i]][_latitudes[i]];

        _tokenIds = conversion.composeBatch(_longitudes, _latitudes);
    }

    function _precheck(
        int256[] memory _longitudes,
        int256[] memory _latitudes,
        string[] memory _uris
    ) private view returns (uint256 _len, uint256 _eventId) {
        _len = _longitudes.length;
        if (_len != _latitudes.length || _len != _uris.length) revert LengthMismatch();

        uint256 _currentTime = block.timestamp;
        string memory _city = coordinates[_longitudes[0]][_latitudes[0]];
        _eventId = eventByCity[keccak256(bytes(_city))];
        if (_currentTime < events[_eventId].start || _currentTime > events[_eventId].end) 
            revert NotStartOrEnded();
        for (uint256 i = 1; i < _len; i++) {
            _city = coordinates[_longitudes[i]][_latitudes[i]];
            if (eventByCity[keccak256(bytes(_city))] != _eventId) revert NotSupported();
        }
    }

    function _isWhitelisted(uint256 _eventId, address _beneficiary) private view {
        if (!whitelist[_eventId][_beneficiary]) revert NotInWhitelist();
    }

    function _makePayment(address _token, address _from, uint256 _amount) private {
        address _treasury = gov.treasury();
        if (_token == address(0))
            Address.sendValue(payable(_treasury), _amount);
        else
            IERC20(_token).safeTransferFrom(_from, _treasury, _amount);
    }
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

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
   @title IGovernance contract
   @dev Provide interfaces that allow interaction to Governance contract
*/
interface IGovernance {
    function treasury() external view returns (address);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function paymentToken(address _token) external view returns (bool);
    function locked() external view returns (bool);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface ILandRegistry {

    /**
       	@notice Mint `_tokenId` to `_to`
       	@dev  Caller must have MINTER_ROLE
		@param	_to			    Beneficiary address to receive a land parcel
		@param	_tokenId		ID number of the token
		@param	_tokenURI		URI to retrieve metadata corresponding to `_tokenId`
    */
    function assignParcel(
        address _to,
        uint256 _tokenId,
        string calldata _tokenURI
    ) external;

    /**
       	@notice Mint a batch of `_tokenIds` to `_to`
       	@dev  Caller must have MINTER_ROLE
		@param	_to			            Address of beneficiary
		@param	_tokenIds		        A list of minting `_tokenIds`
		@param	_tokenURIs		        A list of URIs
    */
    function assignParcels(
        address _to,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenURIs 
    ) external;

    /**
       	@notice Mint a batch of `_tokenIds` to `_receivers`
       	@dev  Caller must have MINTER_ROLE
		@param	_receivers			    A list of Beneficiaries
		@param	_tokenIds		        A list of minting `_tokenIds`
		@param	_tokenURIs		        A list of URIs
    */
    function assignBatchParcels(
        address[] calldata _receivers,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenURIs 
    ) external;

    /**
       	@notice Burn a batch of `_tokenIds`
       	@dev  Caller must have MINTER_ROLE or is the Owner of `_tokenIds`
		@param	_tokenIds		        A list of burning `_tokenIds`
        Note: `LandRegistry` supports a feature that Land's Owner can consolidate adjacent lands to
            create a bigger one. In such case, `LotConsolidate` contract will be assigned MINTER_ROLE to handle it
    */
    function removeBatchParcels(uint256[] calldata _tokenIds) external;

    function ownerOf(uint256 _tokenId) external view returns (address);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface ICoversion {

    /**
        @notice Compose `tokenId` from `_longitude` and `_latitude` values
        @dev  Caller can be ANY
        @param _longitude        Longitude value
        @param _latitude         Latitude value
    */
    function compose(int256 _longitude, int256 _latitude) external view returns (uint256);

    /**
        @notice Compose `tokenId` from `_longitude` and `_latitude` values
        @dev  Caller can be ANY
        @param _longitudes              A list of `_longitude` values
        @param _latitudes               A list of `_latitude` values
    */
    function composeBatch(int256[] calldata _longitudes, int256[] calldata _latitudes) external view returns (uint256[] memory _ids);

    /**
        @notice Decompose `tokenId` to retrieve `_longitude` and `_latitude` values
        @dev  Caller can be ANY
        @param _tokenId             ID number of a token
    */
    function decompose(uint256 _tokenId) external view returns (int256, int256);

    /**
        @notice Decompose a batch of `tokenId`
        @dev  Caller can be ANY
        @param _tokenIds              A list of `_tokenId` to be decomposed
    */
    function decomposeBatch(uint256[] calldata _tokenIds) external view returns (int256[] memory _longitudes, int256[] memory _latitudes);
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