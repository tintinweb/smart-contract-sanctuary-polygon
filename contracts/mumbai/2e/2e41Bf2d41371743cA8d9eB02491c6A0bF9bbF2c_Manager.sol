// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "../interfaces/IFACTORYSELLER.sol"; 
import "../interfaces/IFACTORYHOLDINGS.sol"; 
import "../interfaces/IWHITELIST.sol";
import "../interfaces/INFTSERC721.sol"; 
import "../interfaces/ITOKENHOLDINGS.sol"; 
import "../interfaces/ISELLER.sol"; 
import "../interfaces/IMANAGER.sol";
import "../interfaces/IDIVIDENDS.sol";

interface IOWNABLE {
    function transferOwner(address p_newOwner) external;
}

interface IPAUSE {
    function setPause(bool p_pause) external;
}

contract Manager is IMANAGER, AccessControl { 
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Roles
    //////////////////////////////////////////////////////////////////////////////////////////////////
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////////////////////////////////////////
    address private s_company;
    address private s_whiteList;
    address private s_nftsERC721;
    address private s_factoryHoldings;
    address private s_factorySeller;
    address private s_dividends;
    address private s_contratEventsAggregator;

    mapping(uint256 => address) private s_hodings;
    mapping(address => address) private s_sellers;

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////////////////////////////////////////////
    constructor(
        address p_whiteList,
        address p_nftsERC721,
        address p_factoryERC20,
        address p_factorySeller,
        address p_contratEventsAggregator
    )  {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(EDITOR_ROLE, msg.sender);

        s_company = msg.sender;
        s_whiteList = p_whiteList;
        s_nftsERC721 = p_nftsERC721;
        s_factoryHoldings = p_factoryERC20;
        s_factorySeller = p_factorySeller;
        s_contratEventsAggregator = p_contratEventsAggregator;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    // => View functions

    function whiteList() public view override returns(address) {
        return s_whiteList;
    }

    function nftsERC721() public view override returns(address) {
        return s_nftsERC721;
    }

    function factoryERC20() public view override returns(address) {
        return s_factoryHoldings;
    }

    function factorySeller() public view override returns(address) { 
        return s_factorySeller;
    }

    function addressHoldings(uint256 p_nftID) public view override returns(address) {
        return s_hodings[p_nftID];
    }

    function addressSeller(address p_addressHoldings) public view override returns(address) {
        return s_sellers[p_addressHoldings];
    }

    function addressDividends() public view override returns(address) {
        return s_dividends;
    }

    function company() public view override returns(address) { 
        return s_company;
    }

    // => Set functions

    function revokeRol(bytes32 p_role, address p_address) public override {
        require(hasRole(ADMIN_ROLE, msg.sender), "Without permission");

        _revokeRole(p_role, p_address);
    }

    function addRol(bytes32 p_role, address p_address) public override {
        require(hasRole(ADMIN_ROLE, msg.sender), "Without permission");

        _grantRole(p_role, p_address);
    }

    function setCompany(address p_company) public override {
        require(hasRole(ADMIN_ROLE, msg.sender), "Without permission");

        s_company = p_company;
    }

    function setWhiteList(address p_whiteList) public override {
        require(hasRole(ADMIN_ROLE, msg.sender), "Without permission");

        s_whiteList = p_whiteList;
    }

    function setNftsERC721(address p_nftsERC721) public override {
        require(hasRole(ADMIN_ROLE, msg.sender), "Without permission");

        s_nftsERC721 = p_nftsERC721;
    }

    function setFactoryERC20(address p_factoryERC20) public override {
        require(hasRole(ADMIN_ROLE, msg.sender), "Without permission");

        s_factoryHoldings = p_factoryERC20;
    }

    function setFactorySeller(address p_factorySeller) public override {
        require(hasRole(ADMIN_ROLE, msg.sender), "Without permission");

        s_factorySeller = p_factorySeller;
    } 

    function mintNft(
        uint256 p_amountToSell, 
        string memory p_uri,
        address p_stableCoinAddress,
        address p_beneficiaryAddress,
        address p_aggregatorStableCoinDollar,
        string memory p_name,
        string memory p_symbol
    ) public override {
        require(s_nftsERC721 != address(0), "Error erc721");
        require(s_factoryHoldings != address(0), "Error factory erc20");
        require(s_factorySeller != address(0), "Error factory seller");
        require(
            hasRole(ADMIN_ROLE, msg.sender), 
            "Without permission"
        );

        uint256 nftID = INFTSERC721(s_nftsERC721).mint(); 

        address sellerAddress = IFACTORYSELLER(s_factorySeller).create(p_stableCoinAddress, p_beneficiaryAddress, p_aggregatorStableCoinDollar, s_dividends); 

        s_hodings[nftID] = IFACTORYHOLDINGS(s_factoryHoldings).create(sellerAddress, p_amountToSell, p_name, p_symbol, s_contratEventsAggregator);

        ISELLER(sellerAddress).setHoldingsAddress(s_hodings[nftID]); 

        s_sellers[s_hodings[nftID]] = sellerAddress;

        emit newMint(p_uri, sellerAddress, s_hodings[nftID], s_dividends, nftID);
    } 

    function newSaleSeller(
        uint256 p_priceEUROS,
        uint256 p_maxTimeHours,
        uint256 p_minTokensBuy,
        address p_addressContractSeller
    ) public override {
        require(
            hasRole(ADMIN_ROLE, msg.sender), 
            "Without permission"
        );

        ISELLER(p_addressContractSeller).sell(p_priceEUROS, p_maxTimeHours, p_minTokensBuy);
    }

    function buyThroughCompany(
        uint256 p_amountToken, 
        address p_buyer,
        address p_addressContractSeller
    ) public override { 
        require(
            hasRole(ADMIN_ROLE, msg.sender) ||
            hasRole(MANAGER_ROLE, msg.sender), 
            "Without permission"
        );

        ISELLER(p_addressContractSeller).buyWithFiat(p_amountToken, p_buyer);
    }

    function buyWithoutPay(
        uint256 p_amountToken, 
        address p_buyer,
        address p_addressContractSeller
    ) public override {
        require(
            hasRole(ADMIN_ROLE, msg.sender) ||
            hasRole(MANAGER_ROLE, msg.sender), 
            "Without permission"
        );

        ISELLER(p_addressContractSeller).buyWithoutPay(p_amountToken, p_buyer);
    }

    function setPriceSeller( 
        uint256 p_priceEUROS,
        address p_addressContractSeller
    ) public override {
        require(
            hasRole(ADMIN_ROLE, msg.sender) ||
            hasRole(MANAGER_ROLE, msg.sender), 
            "Without permission"
        );

        ISELLER(p_addressContractSeller).setPrice(p_priceEUROS);
    }

    function setMaxTime(
        uint256 p_maxTimeHours,
        address p_addressContractSeller
    ) public override {
        require(
            hasRole(ADMIN_ROLE, msg.sender) ||
            hasRole(MANAGER_ROLE, msg.sender), 
            "Without permission"
        );

        ISELLER(p_addressContractSeller).setMaxTime(p_maxTimeHours);
    }

    function setMinTokensBuy(
        uint256 p_minTokensBuy,
        address p_addressContractSeller
    ) public override {
        require(
            hasRole(ADMIN_ROLE, msg.sender) ||
            hasRole(MANAGER_ROLE, msg.sender), 
            "Without permission"
        );

        ISELLER(p_addressContractSeller).setMinTokensBuy(p_minTokensBuy); 
    }

    function addDividends(
        address p_addressOrigin, 
        address p_addressContractHoldings, 
        uint256 p_amountIncrementDividends, 
        uint256 p_year, 
        bool p_withholding
    ) public override {
        require(
            hasRole(ADMIN_ROLE, msg.sender),  
            "Without permission"
        );

        IDIVIDENDS(s_dividends).addDividends(p_addressOrigin, p_addressContractHoldings, p_amountIncrementDividends, p_year, p_withholding);
    }

    function activeRevertPayments(address p_seller, address p_origin) public override {
        require(
            hasRole(ADMIN_ROLE, msg.sender),  
            "Without permission"
        );

        ISELLER(p_seller).activeRevertPayments(p_origin);
    }

    function setStatusWhiteList(
        address p_address, 
        IWHITELIST.Status p_status
    ) public override {
        require(
            hasRole(ADMIN_ROLE, msg.sender) ||
            hasRole(MANAGER_ROLE, msg.sender) ||
            hasRole(EDITOR_ROLE, msg.sender), 
            "Without permission"
        );

        require(
            IWHITELIST(s_whiteList).setStatus(p_address, p_status),
            "Error set status" 
        );
    }

    function forcedTransferStocks(address p_address, address p_from, address p_to) public override { 
        require(
            hasRole(ADMIN_ROLE, msg.sender), 
            "Without permission"
        );

        require(
            IWHITELIST(s_whiteList).setStatus(p_to, IWHITELIST.Status.Active) && 
            ITOKENHOLDINGS(p_address).forcedTransferStocks(p_from, p_to),
            "Error forced transfer" 
        );
    }

    function setAddressContractDividends(address p_dividends) public override { 
        require(
            hasRole(ADMIN_ROLE, msg.sender), 
            "Without permission"
        );

        s_dividends = p_dividends;

        IFACTORYHOLDINGS(s_factoryHoldings).setDividends(p_dividends);
    }

    function setOwnable(address p_address, address p_newOwner) public override {
        require(
            hasRole(ADMIN_ROLE, msg.sender), 
            "Without permission"
        );

        IOWNABLE(p_address).transferOwner(p_newOwner);
    }

    function setSignerWhiteList(address p_newSigner) public override { 
        require(
            hasRole(ADMIN_ROLE, msg.sender), 
            "Without permission"
        );

        IWHITELIST(s_whiteList).transferSigner(p_newSigner);
    }

    function setPause(address p_address, bool p_pause) public override {
        require(
            hasRole(ADMIN_ROLE, msg.sender) ||
            hasRole(MANAGER_ROLE, msg.sender), 
            "Without permission"
        );

        IPAUSE(p_address).setPause(p_pause);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWHITELIST {
    enum Status {
        Inactive,
        Active,
        Frozen
    }

    // EVENTS

    event ChangeStatus(address indexed e_address, Status indexed e_status);
    
    // PUBLIC FUNCTIONS

        // View functions

        function status(address p_address) external view returns(Status);

        // Set functions

        function transferOwner(address p_newOwner) external;
        function transferSigner(address p_newSigner) external;
        function setStatus(
            address p_address, 
            Status p_status
        ) external returns(bool);
        function setStatusWithSignature(
            address p_address, 
            Status p_status, 
            uint256 p_timeStamp,
            bytes memory sig
        ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITOKENHOLDINGS {
    // STRUCTS
    
    struct SnapshotInfo {
        uint256 id;
        bool withholding;
    }

    // EVENTS

    event ForcedTransferStocks(address e_from, address e_to); 

    // PUBLIC FUNCTIONS

        // View functions

        function seller() external view returns(address);
        function getCurrentSnapshotId() external view returns(uint256);
        function snapshotsYear(uint256 p_year) external view returns(SnapshotInfo[] memory);
        function yearsWithSnapshots() external view returns(uint256[] memory);
        function amountBuyWithFiat() external view returns(uint256);
        function amountBuyWithFiatUser(address p_buyer) external view returns(uint256);
        function snapshotUsed(address p_account, uint256 p_snapshotId) external view returns(bool);

        // Set functions

        function setPause(bool p_pause) external;
        function snapshotUse(address p_account, uint256 p_snapshotId) external returns(bool);
        function snapshot(uint256 p_year, bool p_withholding) external returns(uint256);
        function incrementAmountBuyWithFiat(uint256 p_amount, address p_buyer) external returns(bool);
        function forcedTransferStocks(address p_from, address p_to) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISELLER {
    // EVENTS

    event newSale(address indexed e_client, uint256 e_amount);
    event newSaleFiat(address indexed e_client, uint256 e_amount);
    event newReinvestment(address indexed e_buyer, uint256 e_amountToken);
    event toSell(uint256 e_tokenAmount, uint256 e_price);
    
    // PUBLIC FUNCTIONS

        // View functions

        function getMaxTime() external view returns(uint256);
        function priceAmountToken(uint256 p_amountToken) external view returns(uint256, uint256);
        function minAmountToBuy() external view returns(uint256);
        function tokenAmountSold() external view returns(uint256);
        function balanceSeller() external view returns(uint256);
        function stableCoin() external view returns(address, string memory, string memory);
        function holdingsAddress() external view returns(address);
        function beneficiary() external view returns(address);
        function canTransferHoldings() external view returns(bool);
        function canRevertPayment() external view returns(bool);
        function amountToActiveRevertPayments() external view returns(uint256);

        // Set functions

        function setHoldingsAddress(address p_erc20) external;
        function buy(uint256 p_amountToken, address p_buyer) external;
        function buyWithoutPay(uint256 p_amountToken, address p_buyer) external;
        function buyWithFiat(uint256 p_amountToken, address p_buyer) external;
        function reinvest(uint256 p_amountToken, address p_buyer) external returns(bool);
        function sell(uint256 p_price, uint256 p_maxTime, uint256 p_minTokensBuy) external;
        function setPrice(uint256 p_price) external;
        function setMaxTime(uint256 p_maxTime) external;
        function setMinTokensBuy(uint256 p_minTokensBuy) external;
        function activeRevertPayments(address p_origin) external ;
        function revertPayment() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface INFTSERC721 {
    // PUBLIC FUNCTIONS

        // View functions

        // Set functions

        function transferOwner(address p_newOwner) external;
        function mint() external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IWHITELIST.sol";

interface IMANAGER {   
    // EVENTS
        event newMint(string indexed uri, address e_seller, address e_holdings, address e_dividends, uint256 e_NftID); 

    // PUBLIC FUNCTIONS

        // View functions

        function whiteList() external view returns(address);
        function nftsERC721() external view returns(address);
        function factoryERC20() external view returns(address);
        function factorySeller() external view returns(address);
        function addressHoldings(uint256 p_nftID) external view returns(address);
        function addressSeller(address p_addressHoldings) external view returns(address);
        function addressDividends() external view returns(address);
        function company() external view returns(address);

        // Set functions

        function revokeRol(bytes32 p_role, address p_address) external;
        function addRol(bytes32 p_role, address p_address) external;
        function setCompany(address p_company) external;
        function setWhiteList(address p_whiteList) external;
        function setNftsERC721(address p_nftsERC721) external;
        function setFactoryERC20(address p_factoryERC20) external;
        function setFactorySeller(address p_factorySeller) external;
        function mintNft(
            uint256 p_amountToSell, 
            string memory p_uri,
            address p_stableCoinAddress,
            address p_beneficiaryAddress,
            address p_aggregatorStableCoinDollar,
            string memory p_name,
            string memory p_symbol
        ) external;
        function newSaleSeller(
            uint256 p_price,
            uint256 p_maxTime,
            uint256 p_minTokensBuy,
            address p_addressContractSeller
        ) external;
        function buyThroughCompany(
            uint256 p_amountToken, 
            address p_buyer,
            address p_addressContractSeller
        ) external;
        function buyWithoutPay(
            uint256 p_amountToken, 
            address p_buyer,
            address p_addressContractSeller
        ) external;
        function setPriceSeller(
            uint256 p_price,
            address p_addressContractSeller
        ) external;
        function setMaxTime(
            uint256 p_maxTime,
            address p_addressContractSeller
        ) external;
        function setMinTokensBuy(
            uint256 p_minTokensBuy,
            address p_addressContractSeller
        ) external;
        function addDividends(
            address p_addressOrigin, 
            address p_addressContractHoldings, 
            uint256 p_amountIncrementDividends, 
            uint256 p_year, 
            bool p_withholding
        ) external;
        function activeRevertPayments(address p_seller, address p_origin) external;
        function setStatusWhiteList(
            address p_address, 
            IWHITELIST.Status p_status
        ) external;
        function forcedTransferStocks(address p_address, address p_from, address p_to) external;
        function setAddressContractDividends(address p_dividends) external;
        function setOwnable(address p_address, address p_newOwner) external;
        function setSignerWhiteList(address p_newSigner) external;
        function setPause(address p_address, bool p_pause) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFACTORYSELLER {
    // PUBLIC FUNCTIONS

        // View functions

        // Set functions

        function setManager(address p_manager) external;
        function create(address p_stableCoin, address p_beneficiary, address p_aggregatorStableCoinDollar, address p_dividends) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFACTORYHOLDINGS {
    // PUBLIC FUNCTIONS

        // View functions

        // Set functions

        function setManager(address p_manager) external;
        function setDividends(address p_dividends) external;
        function create(
            address p_contractAddressSeller,
            uint256 p_amountToSell,
            string memory p_name,
            string memory p_symbol,
            address p_contratEventsAggregator
        ) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDIVIDENDS {
    // EVENTS 

    event AddDividends(
        address indexed e_contractHoldings, 
        uint256 e_amount,
        uint256 e_totalAmount
    ); 
    event ClaimDividends(address indexed e_holder, uint256 e_amount);
    event Reinvest(address indexed e_holder, address indexed e_seller, uint256 e_amount);
    event widhdrawFundsByCompany(address indexed e_contractHoldings, address e_to); 

    // PUBLIC FUNCTIONS

        // View functions

        function amountSnapshots(address p_contractHoldings, uint256 p_idSnapshot) external view returns(uint256);
        function totalAmountSnapshots(address p_contractHoldings) external view returns(uint256);
        function amountSnapshotsAccount(address p_contractHoldings, address p_account, uint256 p_snapshotId) external view returns(uint256, uint256, uint256, bool);

        // Set functions

        function setPause(bool p_pause) external; 
        function addDividends(address p_origin, address p_contractHoldings, uint256 p_amount, uint256 p_year, bool p_retention) external;
        function claimDividends(
            address p_contractHoldings, 
            address p_contractSeller, 
            uint256 p_amountReinvest,
            uint256 p_idSnapshot
        ) external;
        function widhdrawFunds(address p_contractHoldings, address p_to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}