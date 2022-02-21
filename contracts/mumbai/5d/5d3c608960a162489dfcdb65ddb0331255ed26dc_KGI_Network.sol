/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;



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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: contracts/KGI_NETWORK.sol



pragma solidity >=0.7.0 <0.9.0;



//import "./KGI_Network_Interface.sol";

contract KGI_Network is Initializable, OwnableUpgradeable {
    string public name;
    string public version;
    uint256 public minPayment;
    uint256 public minCommission;
    uint256 public defaultWidth;
    uint256 public companyWidth;
    uint256 public defaultDepth;

    uint256 public companyCommission;
    uint256 public sponsorCommission;
    uint256 public uplineCommission;

    mapping(address => Member) private _MemberData;
    address[] private _membership;
    address[] private _nextPossibles;

    event ProductBought(
        uint256 timestamp,
        address member,
        string product,
        uint256 amount
    );
    event MemberAdded(
        uint256 timestamp,
        address member,
        address sponsor,
        address upline
    );
    event MemberPaid(uint256 timestamp, address member, uint256 amount);

    struct Member {
        address wallet;
        uint256 balance;
        uint256 width;
        uint256 depth;
        uint256 expiry;
        address sponsor;
        address upline;
        address[] frontline;
    }

    constructor() initializer {}

    function initialise(string memory _name) public initializer {
        __Ownable_init();

        name = _name;
        version = "1.0.0";
        minPayment = 0.003 ether; // , about $10
        minCommission = 0.0000005 ether; // $0.002
        defaultWidth = 2;
        companyWidth = 2;
        defaultDepth = 2;

        companyCommission = 10;
        sponsorCommission = 20;
        uplineCommission = 5;

        addMember(address(this), address(0), address(0));
        _MemberData[address(this)].width = companyWidth;
    }

    function memberPurchase(address member) public payable {
        memberPurchase(member, address(0), "No description given");
    }

    function memberPurchase(address member, string memory product)
        public
        payable
    {
        memberPurchase(member, address(0), product);
    }

    function memberPurchase(address member, address referral) public payable {
        memberPurchase(member, referral, "No description given");
    }

    function memberPurchase(
        address member,
        address referral,
        string memory product
    ) public payable {
        emit ProductBought(block.timestamp, member, product, msg.value);

        address upline = _membership[0]; //default frontline to company
        address sponsor = _membership[0];

        // check not already a member, search _MemberData for the member address
        // if already a member, just skip to paying the commissions
        if (_MemberData[member].wallet == address(0)) {
            // new member, so need to add
            // if no referral address passed, or referral address is not a member, company is sponsor
            if (
                (referral == address(0)) ||
                (_MemberData[referral].wallet == address(0))
            ) {
                sponsor = _membership[0]; // no referral so sponsored by top
            } else {
                sponsor = referral;
                upline = referral;
            }

            // create an array of possible uplines, as we are just starting that will be just one entry, the sponsor
            // created in storage as needs to be expandable, but could get big!
            //delete _uplinePossibles;
            delete _nextPossibles;
            _nextPossibles.push(sponsor);

            // function checks for a free spot on the frontline of the passed possible uplines
            // builds a new array of frontlines and calls itself recursively down allowed levels (maxDepth)
            // if all allowed levels are full, starts new frontline leg
            upline = findNextFreeSpot(sponsor, _MemberData[sponsor].depth);

            addMember(member, sponsor, upline);
        } else {
            sponsor = _MemberData[member].sponsor;
            upline = _MemberData[member].upline;
        }
        // expiry = now + (numberOfDays * 1 days);  // 30 days for most purchases, others for special memberships
        // if now >= _MemberData[member].expiry
        // so now we know where to start paying commission - sponsor is the sponsor; upline is the 1st upline

        uint256 companyPayment = (msg.value * companyCommission) / 100; //company commission stays in contract
        uint256 sponsorPayment = (msg.value * sponsorCommission) / 100; // deduct sponsor funds
        _MemberData[sponsor].balance += sponsorPayment; // and give it to the sponsor

        // the rest starts going upline till none left or top reached
        // flat rate - x% to anyone upline
        uint256 distributableFunds = msg.value -
            (companyPayment + sponsorPayment);
        uint256 eachUplinePayment = (msg.value * uplineCommission) / 100;

        address payableMember = upline;
        while ((distributableFunds > 0) && (payableMember != address(0))) {
            _MemberData[payableMember].balance += eachUplinePayment;
            distributableFunds -= eachUplinePayment;
            payBalanceDue(payableMember); // check members balance, if greater than minimum withdrawal, send funds
            payableMember = _MemberData[payableMember].upline;
        }
    }

    function findNextFreeSpot(address sponsor, uint256 maxDepth)
        private
        returns (address)
    {
        // function checks for a free spot on the frontline of the passed possible uplines
        // builds a new array of frontlines and calls itself recursively down allowed levels
        // if all allowed levels are full, starts new frontline leg
        address[] memory _uplinePossibles = _nextPossibles;
        delete _nextPossibles;

        for (uint256 i = 0; i < _uplinePossibles.length; i++) {
            // if their frontline isn't as wide as it's allowed to be, put one here
            if (
                _MemberData[_uplinePossibles[i]].frontline.length <
                _MemberData[_uplinePossibles[i]].width
            ) {
                return _uplinePossibles[i];
            }
            // prepare array of next level, to test for an empty spot
            else {
                for (
                    uint256 j = 0;
                    j < _MemberData[_uplinePossibles[i]].frontline.length;
                    j++
                ) {
                    _nextPossibles.push(
                        _MemberData[_uplinePossibles[i]].frontline[j]
                    );
                }
            }
        }

        // need to test how deep we've gone... are we full and can start the next leg?
        // only sponsor can can expand their matrix, can;t be done by an upline placement

        uint256 nextLevel = maxDepth - 1;

        if (nextLevel <= 0) {
            // all levels full, so expand the matrix
            _MemberData[sponsor].width++;
            _MemberData[sponsor].depth++;
            return sponsor;
        }

        // if we get here, didnt find one in that level, but we have an array of that full level
        return findNextFreeSpot(sponsor, nextLevel);
    }

    function payBalanceDue(address member) private {
        if (_MemberData[member].balance >= minPayment) {
            (bool success, ) = payable(member).call{
                value: _MemberData[member].balance
            }("");
            require(success);
            emit MemberPaid(
                block.timestamp,
                member,
                _MemberData[member].balance
            );
            _MemberData[member].balance = 0;
        }
    }

    function addMember(
        address member,
        address sponsor,
        address upline
    ) private {
        _membership.push(member);
        _MemberData[member].wallet = member;
        _MemberData[member].balance = 0;
        _MemberData[member].width = defaultWidth;
        _MemberData[member].depth = defaultDepth;
        _MemberData[member].sponsor = sponsor;
        _MemberData[member].upline = upline;

        _MemberData[upline].frontline.push(member);

        emit MemberAdded(block.timestamp, member, sponsor, upline);
    }

    /******************************** public view functions, probably required for website ******************/

    function getNumMembers() public view returns (uint256) {
        return _membership.length;
    }

    function getMemberData(address member)
        public
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _MemberData[member].wallet,
            _MemberData[member].sponsor,
            _MemberData[member].upline,
            _MemberData[member].balance,
            _MemberData[member].width,
            _MemberData[member].depth
        );
    }

    function getMemberFrontline(address member)
        public
        view
        returns (address[] memory)
    {
        address[] memory frontline = new address[](
            _MemberData[member].frontline.length
        );

        for (uint256 i = 0; i < _MemberData[member].frontline.length; i++) {
            frontline[i] = _MemberData[member].frontline[i];
        }
        return (frontline);
    }

    /******************************** owner only functions ******************/

    function setVersion(string memory _newVersion) public onlyOwner {
        version = _newVersion;
    }

    function setMinPayment(uint256 _newMinPayment) public onlyOwner {
        minPayment = _newMinPayment;
    }

    function setMinCommission(uint256 _newMinCommission) public onlyOwner {
        minCommission = _newMinCommission;
    }

    function setDefaultWidth(uint256 _newDefaultWidth) public onlyOwner {
        defaultWidth = _newDefaultWidth;
    }

    function setDefaultDepth(uint256 _newDefaultDepth) public onlyOwner {
        defaultDepth = _newDefaultDepth;
    }

    function setCompanyCommission(uint256 _newCompanyCommission)
        public
        onlyOwner
    {
        companyCommission = _newCompanyCommission;
    }

    function setSponsorCommission(uint256 _newSponsorCommission)
        public
        onlyOwner
    {
        sponsorCommission = _newSponsorCommission;
    }

    function setUplineCommission(uint256 _newUplineCommission)
        public
        onlyOwner
    {
        uplineCommission = _newUplineCommission;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    /**************************************************** test purposes only ******************************/

    function clearMembership() public onlyOwner {
        for (uint256 i = 0; i < _membership.length; i++) {
            _MemberData[_membership[i]].wallet = address(0);
            _MemberData[_membership[i]].balance = 0;
            _MemberData[_membership[i]].width = 0;
            _MemberData[_membership[i]].depth = 0;
            _MemberData[_membership[i]].sponsor = address(0);
            _MemberData[_membership[i]].upline = address(0);
        }
        delete _membership;

        // re-initialise with top spot (company)
        addMember(address(this), address(0), address(0));
        _MemberData[address(this)].width = companyWidth;
    }
}