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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
pragma solidity >=0.7.0 <0.9.0;

interface IChainPost {
    function numSupported() external view returns (uint tokens, uint feeds);

    function supportedTokens() external view returns (string[] memory);

    function findPair(string memory symbol, string memory basePair)
        external
        view
        returns (address tknAddr, address pfAddr);

    function dollarAmountToTokens(int dollars, string memory symbol)
        external
        view
        returns (int);

    function isGas(string memory symbol) external view returns (bool);

    function userCanPay(address user, int dollars) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "../ISkeletonKeyDB.sol";
import "./IAsset.sol";

/**
 * @title Asset
 * @dev Standalone Asset template for SkeletonKeyDB compatibility
 *
 * @author CyAaron Tai Nava || hemlockStreet.x
 */

abstract contract Asset is IAsset {
    address private _deployer;
    address private _skdb;
    address private _asset;

    /**
     * @dev Constructor
     *
     * @param db SkeletonKeyDB address
     *
     * @param asset Javascript `==` logic applies. (falsy & truthy values)
     * Use `address(0)` for standalone assets (typically Web2-based) assets.
     * Use actual asset address otherwise
     */
    constructor(address db, address asset) {
        _skdb = db;
        _deployer = msg.sender;
        bool standalone = asset == address(0);
        _asset = standalone ? address(this) : asset;
    }

    function _skdbMetadata()
        public
        view
        override
        returns (
            address asset,
            address skdb,
            address deployer
        )
    {
        asset = _asset;
        skdb = _skdb;
        deployer = _deployer;
    }

    function _owner() internal view returns (address) {
        return ISkeletonKeyDB(_skdb).skeletonKeyHolder(_asset);
    }

    function _skdbAccessTier(address user) internal view returns (uint) {
        return ISkeletonKeyDB(_skdb).accessTier(_asset, user);
    }

    modifier RequiredTier(uint tier) {
        require(_skdbAccessTier(msg.sender) >= tier, "!Authorized");
        _;
    }

    function _setSkdb(address newDb) public override RequiredTier(3) {
        _skdb = newDb;
    }

    function _setAsset(address newAst) public override RequiredTier(3) {
        require((newAst != _asset) && (_asset != address(this)), "disabled");
        _asset = newAst;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IAsset
 * @dev Standard Asset Interface for SkeletonKeyDB
 *
 * @author CyAaron Tai Nava || hemlockStreet.x
 */
interface IAsset {
    function _skdbMetadata()
        external
        view
        returns (
            address asset,
            address skdb,
            address deployer
        );

    function _setSkdb(address newDb) external;

    function _setAsset(address newAst) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title ISkeletonKeyDB
 * @dev SkeletonKeyDB Interface
 *
 * @author CyAaron Tai Nava || hemlockStreet.x
 */
interface ISkeletonKeyDB {
    function skeletonKeyHolder(address asset) external view returns (address);

    function executiveKeyHolder(address asset) external view returns (address);

    function adminKeyHolders(address asset)
        external
        view
        returns (address[] memory);

    function akIds(address asset) external view returns (uint[] memory ids);

    function diag(address asset)
        external
        view
        returns (
            address skHolder,
            address skToken,
            uint skId,
            address ekHolder,
            address ekToken,
            uint ekId,
            address[] memory akHolders,
            address akToken,
            uint[] memory akId
        );

    function isAdminKeyHolder(address asset, address user)
        external
        view
        returns (bool);

    function accessTier(address asset, address holder)
        external
        view
        returns (uint);

    function defineSkeletonKey(
        address asset,
        address token,
        uint id
    ) external;

    function defineExecutiveKey(
        address asset,
        address token,
        uint id
    ) external;

    function defineAdminKey(
        address asset,
        address token,
        uint[] memory ids
    ) external;

    function manageAdmins(
        address asset,
        uint[] memory ids,
        bool grant
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IStoreFront {
    struct Invoice {
        address recipient; // original address issued to
        address by; // person who paid (address(0) if self)
        string cid; // file location
        int total; // dollars
        uint issued; // timestamp
        uint dueDate; // timestamp
        uint paid; // timestamp
        string symbol; // payment method token symbol
        address token; // payment method token address (address(0) if gas)
        int amount; // payment method token amount
    }

    function availablePaymentMethods() external view returns (string[] memory);

    function invoice(uint idx) external view returns (Invoice memory);

    function breakdown()
        external
        view
        returns (
            uint[] memory involvedInvoices,
            uint[] memory expiredInvoices,
            uint[] memory unpaidInvoices,
            uint[] memory paidInvoices
        );

    function _breakdown(address recipient)
        external
        view
        returns (
            uint[] memory involvedInvoices,
            uint[] memory expiredInvoices,
            uint[] memory unpaidInvoices,
            uint[] memory paidInvoices
        );

    function cancel(uint idx) external;

    function create(
        address recipient,
        string memory cid,
        int total,
        uint timeToPay
    ) external;

    function replace(
        uint idx,
        address recipient,
        string memory cid,
        int total,
        uint timeToPay
    ) external;

    function pay(uint idx, string memory symbol) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IStoreFront.sol";
import "../ChainPost/IChainPost.sol";
import "../SkeletonKeyDB/Asset/Asset.sol";

contract StoreFront is IStoreFront, Asset {
    address public _chainPost;

    function chainPost() internal view returns (IChainPost) {
        return IChainPost(_chainPost);
    }

    function _setChainPost(address addr) public RequiredTier(2) {
        _chainPost = addr;
    }

    mapping(string => bool) internal _accepted;

    function _togglePaymentMethod(string memory mtd) public RequiredTier(1) {
        _accepted[mtd] = !_accepted[mtd];
    }

    function availablePaymentMethods()
        public
        view
        override
        returns (string[] memory)
    {
        string[] memory cpMtds = chainPost().supportedTokens();

        uint numAccepted = 0;
        for (uint i = 0; i < cpMtds.length; i++) {
            string memory method = cpMtds[i];
            if (_accepted[method]) numAccepted++;
        }

        string[] memory result = new string[](numAccepted);
        uint idx = 0;
        for (uint i = 0; i < cpMtds.length; i++) {
            string memory method = cpMtds[i];
            if (_accepted[method]) {
                result[idx] = method;
                idx++;
            }
        }

        return result;
    }

    constructor(address cp, address db) Asset(db, address(0)) {
        _chainPost = cp;
        _accepted["WETH"] = true;
        _accepted["ETH"] = true;
        _accepted["WBTC"] = true;
        _accepted["USDC"] = true;
    }

    mapping(uint => Invoice) internal _invoices;
    uint public numInvoices;

    modifier Eligible(uint idx) {
        bool notExpired = (block.timestamp < _invoices[idx].dueDate);
        bool unpaid = (_invoices[idx].paid == 0);
        require(notExpired && unpaid, "!replacable");
        _;
    }

    function invoice(uint idx) public view override returns (Invoice memory) {
        Invoice memory inv = _invoices[idx];
        require(
            _skdbAccessTier(msg.sender) >= 1 || msg.sender == inv.recipient,
            "!Authorized"
        );
        return inv;
    }

    function _involving(address recipient)
        internal
        view
        returns (uint[] memory)
    {
        uint numInvolving = 0;
        for (uint i = 1; i <= numInvoices; i++) {
            if (recipient == _invoices[i].recipient) numInvolving++;
        }

        uint[] memory result = new uint[](numInvolving);
        uint idx = 0;
        for (uint i = 1; i <= numInvoices; i++) {
            if (recipient == _invoices[i].recipient) {
                result[idx] = i;
                idx++;
            }
        }
        return result;
    }

    function _expired(address recipient) internal view returns (uint[] memory) {
        uint numExpired = 0;
        uint[] memory involved = _involving(recipient);
        for (uint i = 0; i < involved.length; i++) {
            Invoice memory inv = _invoices[involved[i]];
            if (inv.paid == 0 && inv.dueDate < block.timestamp) numExpired++;
        }

        uint[] memory result = new uint[](numExpired);
        uint idx = 0;
        for (uint i = 0; i < involved.length; i++) {
            Invoice memory inv = _invoices[involved[i]];
            if (inv.paid == 0 && inv.dueDate < block.timestamp) {
                result[idx] = involved[i];
                idx++;
            }
        }

        return result;
    }

    function _pending(address recipient) internal view returns (uint[] memory) {
        uint numPending = 0;
        uint[] memory involved = _involving(recipient);
        for (uint i = 0; i < involved.length; i++) {
            Invoice memory inv = _invoices[involved[i]];
            if (inv.paid == 0 && inv.dueDate > block.timestamp) numPending++;
        }

        uint[] memory result = new uint[](numPending);
        uint idx = 0;
        for (uint i = 0; i < involved.length; i++) {
            Invoice memory inv = _invoices[involved[i]];
            if (inv.paid == 0 && inv.dueDate > block.timestamp) {
                result[idx] = involved[i];
                idx++;
            }
        }

        return result;
    }

    function _complete(address recipient)
        internal
        view
        returns (uint[] memory)
    {
        uint numPending = 0;
        uint[] memory involved = _involving(recipient);
        for (uint i = 0; i < involved.length; i++) {
            if (_invoices[involved[i]].paid != 0) numPending++;
        }

        uint[] memory result = new uint[](numPending);
        uint idx = 0;
        for (uint i = 0; i < involved.length; i++) {
            if (_invoices[involved[i]].paid != 0) {
                result[idx] = involved[i];
                idx++;
            }
        }

        return result;
    }

    function breakdown()
        public
        view
        override
        returns (
            uint[] memory involvedInvoices,
            uint[] memory expiredInvoices,
            uint[] memory unpaidInvoices,
            uint[] memory paidInvoices
        )
    {
        involvedInvoices = _involving(msg.sender);
        expiredInvoices = _expired(msg.sender);
        unpaidInvoices = _pending(msg.sender);
        paidInvoices = _complete(msg.sender);
    }

    function _breakdown(address recipient)
        public
        view
        override
        RequiredTier(1)
        returns (
            uint[] memory involvedInvoices,
            uint[] memory expiredInvoices,
            uint[] memory unpaidInvoices,
            uint[] memory paidInvoices
        )
    {
        involvedInvoices = _involving(recipient);
        expiredInvoices = _expired(recipient);
        unpaidInvoices = _pending(recipient);
        paidInvoices = _complete(recipient);
    }

    function cancel(uint idx) public RequiredTier(1) {
        delete _invoices[idx];
    }

    function _generate(
        address recipient,
        string memory cid,
        int total,
        uint daysToPay
    ) internal view returns (Invoice memory) {
        uint numDays = daysToPay == 0 ? 3 : daysToPay;
        uint issued = block.timestamp;
        uint timeToPay = numDays * (60 * 60 * 24);
        uint dueDate = issued + timeToPay;

        Invoice memory template = _invoices[0];

        template.recipient = recipient;
        template.cid = cid;
        template.total = total;
        template.issued = issued;
        template.dueDate = dueDate;

        return template;
    }

    function create(
        address recipient,
        string memory cid,
        int total,
        uint daysToPay
    ) public override RequiredTier(1) {
        numInvoices++;
        _invoices[numInvoices] = _generate(recipient, cid, total, daysToPay);
    }

    function replace(
        uint idx,
        address recipient,
        string memory cid,
        int total,
        uint daysToPay
    ) public override RequiredTier(1) Eligible(idx) {
        _invoices[idx] = _generate(recipient, cid, total, daysToPay);
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked(a)) ==
            keccak256(abi.encodePacked(b)));
    }

    function pay(uint idx, string memory symbol)
        external
        payable
        override
        Eligible(idx)
    {
        if (msg.value != 0) require(chainPost().isGas(symbol), "!Gas");

        Invoice memory inv = _invoices[idx];
        int expected = chainPost().dollarAmountToTokens(inv.total, symbol);

        if (msg.value == 0) {
            (address tknAddr, ) = chainPost().findPair(symbol, "USD");
            IERC20(tknAddr).transferFrom(
                msg.sender,
                address(this),
                uint(expected)
            );
            inv.token = tknAddr;
        } else {
            require(msg.value == uint(expected), "!InvalidValue");
            inv.token = address(0);
        }

        inv.by = msg.sender;
        inv.paid = block.timestamp;
        inv.symbol = symbol;
        inv.amount = expected;

        _invoices[idx] = inv;
    }

    function cashout(string[] memory symbols) public {
        uint gasBalance = address(this).balance;
        for (uint i = 0; i < symbols.length; i++) {
            string memory symbol = symbols[i];

            if (chainPost().isGas(symbol) && gasBalance != 0)
                payable(_owner()).transfer(gasBalance);

            (address tknAddr, ) = chainPost().findPair(symbol, "USD");
            IERC20Metadata token = IERC20Metadata(tknAddr);
            uint bal = token.balanceOf(address(this));
            uint allowance = token.allowance(address(this), address(this));
            uint max_uint = (2**255) + ((2**255) - 1);
            if (bal >= allowance) token.approve(address(this), max_uint);
            token.transferFrom(address(this), _owner(), bal);
        }
    }
}