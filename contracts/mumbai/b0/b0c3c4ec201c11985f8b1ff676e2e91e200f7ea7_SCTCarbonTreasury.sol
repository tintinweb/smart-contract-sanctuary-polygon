/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

// SPDX-License-Identifier: MIT

/**
 * @author Solid World DAO
 * @notice SCT Carbon Credits Treasury
 */

// File: interfaces/IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.13;

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
// File: interfaces/ISCT.sol


pragma solidity 0.8.13;


interface ISCT is IERC20 {
  function mint(address account_, uint256 amount_) external;

  function burn(uint256 amount) external;

  function burnFrom(address account_, uint256 amount_) external;
}

// File: interfaces/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.13;

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
// File: interfaces/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity 0.8.13;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
// File: lib/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity 0.8.13;


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
// File: interfaces/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity 0.8.13;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
// File: lib/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity 0.8.13;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
// File: interfaces/ISolidDaoManagement.sol


pragma solidity 0.8.13;

interface ISolidDaoManagement {
    
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);    

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);
    
    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
}
// File: lib/SolidDaoManaged.sol


pragma solidity 0.8.13;


/**
 * @title Solid Dao Managed
 * @author Solid World DAO
 * @notice Abstract contratc to implement Solid Dao Management and access control modifiers 
 */
abstract contract SolidDaoManaged {

    /**
    * @dev Emitted on setAuthority()
    * @param authority Address of Solid Dao Management smart contract
    **/
    event AuthorityUpdated(ISolidDaoManagement indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED";

    ISolidDaoManagement public authority;

    constructor(ISolidDaoManagement _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    
    /**
    * @notice Function modifier that can be used in other smart contracts
    * @dev Only governor address can call functions marked by this modifier
    **/
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    /**
    * @notice Function modifier that can be used in other smart contracts
    * @dev Only guardian address can call functions marked by this modifier
    **/
    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }
    
    /**
    * @notice Function modifier that can be used in other smart contracts
    * @dev Only policy address can call functions marked by this modifier
    **/
    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    /**
    * @notice Function modifier that can be used in other smart contracts
    * @dev Only vault address can call functions marked by this modifier
    **/
    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /**
    * @notice Function to set and update Solid Dao Management smart contract address
    * @dev Emit AuthorityUpdated event
    * @param _newAuthority Address of the new Solid Dao Management smart contract
    */ 
    function setAuthority(ISolidDaoManagement _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// File: SCTCarbonTreasury.sol



pragma solidity 0.8.13;





/**
 * @title SCT Carbon Treasury
 * @author Solid World DAO
 * @notice SCT Carbon Credits Treasury
 */
contract SCTCarbonTreasury is SolidDaoManaged, ERC1155Receiver {

    event Deposited(address indexed token, uint256 indexed tokenId, address indexed owner, uint256 amount);
    event CreatedOffer(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 totalValue);
    event CanceledOffer(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 totalValue);
    event Sold(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed owner, address buyer, uint256 amount, uint256 totalValue);
    event UpdatedInfo(address indexed token, uint256 indexed tokenId, bool isActive);
    event ChangedTimelock(bool timelock);
    event SetOnChainGovernanceTimelock(uint256 blockNumber);
    event Permissioned(STATUS indexed status, address token, bool result);
    event PermissionOrdered(STATUS indexed status, address token);

    /**
     * @notice SCT
     * @dev immutable variable to store SCT ERC20 token address
     * @return address
     */
    ISCT public immutable SCT;
    
    /**
     * @notice totalReserves
     * @dev variable to store SCT ERC20 token address
     * @return uint256
     */
    uint256 public totalReserves;

    /**
     * @notice CarbonProject
     * @dev struct to store carbon project details
     * @param token: ERC1155 smart contract address 
     * @param tokenId: ERC1155 carbon project token id
     * @param tons: total amount of carbon project tokens
     * @param flatRate: premium price variable
     * @param sdgPremium: premium price variable
     * @param daysToRealization: premium price variable
     * @param closenessPremium: premium price variable
     * @param isActive: boolean status of carbon project in this smart contract
     * @param isCertified: boolean verra status of carbon project certificate
     * @param isRedeemed: boolean status of carbon project redeem
     */
    struct CarbonProject {
        address token;
        uint256 tokenId;
        uint256 tons;
        uint256 flatRate;
        uint256 sdgPremium;
        uint256 daysToRealization;
        uint256 closenessPremium;
        bool isActive;
        bool isCertified;
        bool isRedeemed;
    }

    /**
     * @notice carbonProjects
     * @dev mapping with token and tokenId as keys to store CarbonProjects
     * @dev return CarbonProject
     */
    mapping(address => mapping(uint256 => CarbonProject)) public carbonProjects; 

    /**
     * @notice carbonProjectTons
     * @dev mapping with token and tokenId as keys to store total amount of ERC1155 carbon project deposited in this contract
     * @return uint256
     */
    mapping(address => mapping(uint256 => uint256)) public carbonProjectTons;

    /**
     * @notice carbonProjectBalances
     * @dev mapping with token, tokenId and owner address as keys to store the amount of each ERC1155 carbon project owner deposited
     * @return uint256
     */
    mapping(address => mapping(uint256 => mapping(address => uint256))) public carbonProjectBalances;

    /**
     * @notice Offer
     * @dev enum of offer status
     * @dev 0 OPEN
     * @dev 1 EXECUTED
     * @dev 2 CANCELED
     */
    enum StatusOffer {
        OPEN,
        EXECUTED,
        CANCELED
    }

    /**
     * @notice Offer
     * @dev struct to store ERC1155 carbon project buy offers
     * @param token: ERC1155 carbon project smart contract address 
     * @param tokenId: ERC1155 carbon project token id
     * @param buyer: address of buyer
     * @param amount: amount of ERC1155 carbon project tokens to buy
     * @param totalValue: amount of SCT tokens to pay for the sale
     * @param statusOffer: enum StatusOffer
     */
    struct Offer {
        address token;
        uint256 tokenId;
        address buyer;
        uint256 amount;
        uint256 totalValue;
        StatusOffer statusOffer;
    }

    /**
     * @notice offers
     * @dev mapping with offerId as key to store Offers
     * @dev return Offer
     */
    mapping(uint256 => Offer) public offers;

    /**
     * @notice offerIdCounter
     * @dev variable to count the ids of offers
     * @return uint256
     */
    uint256 public offerIdCounter;

    /**
     * @notice STATUS
     * @dev enum of permisions types
     * @dev 0 RESERVETOKEN
     * @dev 1 RESERVEMANAGER
     */
    enum STATUS {
        RESERVETOKEN,
        RESERVEMANAGER
    }

    /**
     * @notice Order
     * @dev struct to store orders created on the timelock
     * @param managing: STATUS enum to be enabled
     * @param toPermit: address to recieve permision
     * @param timelockEnd: due date of the order in blocks
     * @param nullify: boolean to verify if the order is null
     * @param executed: boolean to verify if the order is executed
     */
    struct Order {
        STATUS managing;
        address toPermit;
        uint256 timelockEnd;
        bool nullify;
        bool executed;
    }

    /**
     * @notice registry
     * @dev mapping with STATUS as key to store an array of addresses
     * @return array of addresses
     */
    mapping(STATUS => address[]) public registry;

    /**
     * @notice permissions
     * @dev mapping with STATUS and address as keys to store status of permisions
     * @return bool
     */
    mapping(STATUS => mapping(address => bool)) public permissions;
    
    /**
     * @notice permissionOrder
     * @dev array of Orders
     * @dev return Order[]
     */
    Order[] public permissionOrder;

    /**
     * @notice blocksNeededForOrder
     * @dev immutable variable set in constructor to store number of blocks that order needed to stay in queue to be executed 
     * @return uint256
     */
    uint256 public immutable blocksNeededForOrder;

    /**
     * @notice timelockEnabled
     * @dev variable to store if smart contract timelock is enabled
     * @return boolean
     */
    bool public timelockEnabled;

    /**
     * @notice initialized
     * @dev variable to store if smart contract is initialized
     * @return boolean
     */
    bool public initialized;
    
    /**
     * @notice onChainGovernanceTimelock
     * @dev variable to store the block number that disableTimelock function can change timelockEnabled to true
     * @return uint256
     */
    uint256 public onChainGovernanceTimelock;

    /**
     * @notice constructor
     * @dev this is executed when this contract is deployed
     * @dev set timelockEnabled and initialized to false
     * @dev set blocksNeededForOrder
     * @param _authority address
     * @param _sct address
     * @param _timelock unint256
     */
    constructor(
        address _authority,
        address _sct,
        uint256 _timelock
    ) SolidDaoManaged(ISolidDaoManagement(_authority)) {
        require(_sct != address(0), "SCT Treasury: invalid SCT address");
        SCT = ISCT(_sct);
        timelockEnabled = false;
        initialized = false;
        blocksNeededForOrder = _timelock;
    }

    /**
     * @notice initialize
     * @dev this function enable timelock and set initialized to true
     * @dev only governor can call this function
     */
    function initialize() external onlyGovernor {
        require(!initialized, "SCT Treasury: already initialized");
        timelockEnabled = true;
        initialized = true;
    }

    /**
     * @notice depositReserveToken
     * @notice function to deposit an _amount of ERC1155 carbon project token in SCT Treasury and mint the same _amount of SCT
     * @dev only permitted reserve tokens are accepted
     * @dev only active carbon projects are accepted
     * @dev owner ERC1155 carbon project token balance needs to be more or equal than _amount
     * @dev owner need to allow this contract spend ERC1155 carbon project token before execute this function
     * @dev update _owner carbonProjectBalances and smart contract carbonProjectTons
     * @param _token address
     * @param _tokenId unint256
     * @param _amount unint256
     * @param _owner address
     * @return true
     */
    function depositReserveToken(
        address _token,
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external returns (bool) {
        require(permissions[STATUS.RESERVETOKEN][_token], "SCT Treasury: reserve token not permitted");
        require(carbonProjects[_token][_tokenId].isActive, "SCT Treasury: carbon project not active");
        require((IERC1155(_token).balanceOf(_owner, _tokenId)) >= _amount, "SCT Treasury: owner insuficient ERC1155 balance");
        require((IERC1155(_token).isApprovedForAll(_owner, address(this))) , "SCT Treasury: owner not approved this contract spend ERC1155");

        IERC1155(_token).safeTransferFrom(
            _owner, 
            address(this), 
            _tokenId, 
            _amount, 
            "data"
        );

        SCT.mint(_owner, _amount);

        carbonProjectBalances[_token][_tokenId][_owner] += _amount;
        carbonProjectTons[_token][_tokenId] += _amount;
        totalReserves += _amount;

        emit Deposited(_token, _tokenId, _owner, _amount);
        return true;
    }

    /**
     * @notice createOffer
     * @notice function to create an offer to buy deposited ERC1155 carbon project tokens
     * @notice when the offer is created the buyer deposits _offer.totalValue SCT tokens in this smart contract
     * @notice to remove an OPEN offer, buyer needs to cancel the offer using cancelOffer function
     * @dev only active carbon projects are accepted
     * @dev ERC1155 carbon project tokens deposited in this smart contract needs to be equal or more than _offer.amount
     * @dev SCT _offer.totalValue needs to be equal or more than ERC1155 carbon project tokens _offer.amount
     * @dev only _offer.buyer can call this function
     * @dev msg.sender need to approve this smart contract spend _offer.totalValue of SCT tokens before execute this function
     * @dev to prevent msg.sender lose his SCT tokens this function automatically set offer status to OPEN
     * @param _offer struct Offer
     * @return offerId uint256
     */
    function createOffer(Offer memory _offer) external returns (uint256) {
        require(carbonProjects[_offer.token][_offer.tokenId].isActive, "SCT Treasury: carbon project not active");
        require(carbonProjectTons[_offer.token][_offer.tokenId]  >= _offer.amount, "SCT Treasury: ERC1155 deposited insuficient");
        require(_offer.totalValue >= _offer.amount, "SCT Treasury: SCT total value needs to be more or equal than ERC1155 amount");
        require(_offer.buyer == msg.sender, "SCT Treasury: msg.sender is not the buyer");
        require((SCT.allowance(msg.sender, address(this))) >= _offer.totalValue, "SCT Treasury: buyer not allowed this contract spend SCT");

        SCT.transferFrom(msg.sender, address(this), _offer.totalValue);

        offerIdCounter ++;
        offers[offerIdCounter] = _offer;
        offers[offerIdCounter].statusOffer = StatusOffer.OPEN;

        emit CreatedOffer(offerIdCounter, _offer.token, _offer.tokenId, msg.sender, _offer.amount, _offer.totalValue);
        return offerIdCounter;
    }

    /**
     * @notice cancelOffer
     * @notice function to cancel an offer to buy deposited ERC1155 carbon project tokens
     * @notice when the offer is canceled the msg.sender recieve the amount of offer.totalValue SCT tokens from this smart contract
     * @dev only OPEN offers can be canceled
     * @dev only offer.buyer can call this function
     * @dev change offer.statusOffer to CANCELED
     * @param _offerId uint256 offerId
     * @return true
     */
    function cancelOffer(uint256 _offerId) external returns (bool) {
        require(offers[_offerId].statusOffer == StatusOffer.OPEN, "SCT Treasury: offer is not OPEN");
        require(offers[_offerId].buyer == msg.sender, "SCT Treasury: msg.sender is not the buyer");

        offers[_offerId].statusOffer = StatusOffer.CANCELED;

        SCT.transferFrom(address(this), msg.sender, offers[_offerId].totalValue);

        emit CanceledOffer(_offerId, offers[_offerId].token, offers[_offerId].tokenId, msg.sender, offers[_offerId].amount, offers[_offerId].totalValue);
        return true;
    }

    /**
     * @notice acceptOffer
     * @notice function to accept an offer to buy offer.amount from msg.sender/owner ERC1155 carbon project tokens deposited in this contract
     * @notice burns the offer.amount of SCT deposited in this contract 
     * @notice transfers the difference between offer.totalValue and offer.amount of SCT deposited in this contract to msg.sender/owner
     * @notice transfers to the buyer the offer.amount of ERC1155 carbon project tokens deposited in this contract
     * @dev for security reasons, to execute a sale in this contract it is necessary buyer create some offer first and only OPEN offers are accepted
     * @dev only active carbon projects can be sold
     * @dev only OPEN offer can be executed in this function
     * @dev msg.sender/owner ERC1155 carbon project tokens balance needs to be equal or more than offer.amount
     * @dev update owner carbonProjectBalances and smart contract carbonProjectTons
     * @dev change offer.statusOffer to EXECUTED
     * @param _offerId offer id
     * @return true     
     */
    function acceptOffer(uint256 _offerId) external returns (bool) {

        Offer memory offer = offers[_offerId];

        require(carbonProjects[offer.token][offer.tokenId].isActive, "SCT Treasury: carbon project not active");
        require(offer.statusOffer == StatusOffer.OPEN, "SCT Treasury: offer is not OPEN");
        require(carbonProjectBalances[offer.token][offer.tokenId][msg.sender] >= offer.amount, "SCT Treasury: caller deposited balance insuficient");

        offers[_offerId].statusOffer = StatusOffer.EXECUTED;

        carbonProjectBalances[offer.token][offer.tokenId][msg.sender] -= offer.amount;
        carbonProjectTons[offer.token][offer.tokenId] -= offer.amount;
        totalReserves -= offer.amount;

        SCT.burn(offer.amount);

        if(offer.totalValue - offer.amount > 0) {
            SCT.transfer(msg.sender, offer.totalValue - offer.amount);
        }
        
        IERC1155(offer.token).safeTransferFrom( 
            address(this), 
            offer.buyer,
            offer.tokenId, 
            offer.amount, 
            "data"
        );

        emit Sold(_offerId, offer.token, offer.tokenId, msg.sender, offer.buyer, offer.amount, offer.totalValue);
        return true;
    }

    /**
     * @notice createOrUpdateCarbonProject
     * @notice function to create or update carbon project
     * @dev only permitted reserve manager can call this function
     * @dev only permitted reserve tokens are accepted
     * @param _carbonProject CarbonProject
     * @return true
     */
    function createOrUpdateCarbonProject(CarbonProject memory _carbonProject) external returns (bool) {
        require(permissions[STATUS.RESERVEMANAGER][msg.sender], "SCT Treasury: reserve manager not permitted");
        require(permissions[STATUS.RESERVETOKEN][_carbonProject.token], "SCT Treasury: reserve token not permitted");

        carbonProjects[_carbonProject.token][_carbonProject.tokenId] = _carbonProject;

        emit UpdatedInfo(_carbonProject.token, _carbonProject.tokenId, _carbonProject.isActive);
        return true;
    }

    /**
     * @notice enable
     * @notice function to enable permission
     * @dev only governor can call this function
     * @dev timelock needs to be disabled
     * @dev if timelock is enable use orderTimelock function
     * @param _status STATUS
     * @param _address address
     * @return true
     */
    function enable(
        STATUS _status,
        address _address
    ) external onlyGovernor returns(bool) {
        require(!timelockEnabled, "SCT Treasury: timelock enabled");

        permissions[_status][_address] = true;
        (bool registered, ) = indexInRegistry(_address, _status);
        if (!registered) {
            registry[_status].push(_address);
        }

        emit Permissioned(_status, _address, true);
        return true;
    }

    /**
     * @notice disable
     * @notice function to disable permission
     * @dev only governor can call this function
     * @param _status STATUS
     * @param _address address
     * @return true
     */
    function disable(
        STATUS _status, 
        address _address
    ) external onlyGovernor returns(bool) {

        permissions[_status][_address] = false;

        emit Permissioned(_status, _address, false);
        return true;
    }

    /**
     * @notice indexInRegistry
     * @notice view function to check if registry contains address
     * @return (bool, uint256)
     */
    function indexInRegistry(address _address, STATUS _status) public view returns (bool, uint256) {
        address[] memory entries = registry[_status];
        for (uint256 i = 0; i < entries.length; i++) {
            if (_address == entries[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @notice orderTimelock
     * @notice function to create order for address receive permission
     * @dev only governor can call this function
     * @param _status STATUS
     * @param _address address
     * @return true
     */
    function orderTimelock(
        STATUS _status,
        address _address
    ) external onlyGovernor returns(bool) {
        require(_address != address(0), "SCT Treasury: invalid address");
        require(timelockEnabled, "SCT Treasury: timelock is disabled, use enable");

        uint256 timelock = block.number + blocksNeededForOrder;
        permissionOrder.push(
            Order({
                managing: _status, 
                toPermit: _address, 
                timelockEnd: timelock, 
                nullify: false, 
                executed: false
            })
        );

        emit PermissionOrdered(_status, _address);
        return true;
    }

    /**
     * @notice execute
     * @notice function to enable ordered permission
     * @dev only governor can call this function
     * @param _index uint256
     * @return true
     */
    function execute(uint256 _index) external onlyGovernor returns(bool) {
        require(timelockEnabled, "SCT Treasury: timelock is disabled, use enable");

        Order memory info = permissionOrder[_index];

        require(!info.nullify, "SCT Treasury: order has been nullified");
        require(!info.executed, "SCT Treasury: order has already been executed");
        require(block.number >= info.timelockEnd, "SCT Treasury: timelock not complete");

        permissions[info.managing][info.toPermit] = true;
        (bool registered, ) = indexInRegistry(info.toPermit, info.managing);
        if (!registered) {
            registry[info.managing].push(info.toPermit);
        }
        permissionOrder[_index].executed = true;

        emit Permissioned(info.managing, info.toPermit, true);
        return true;
    }

    /**
     * @notice nullify
     * @notice function to cancel timelocked order
     * @dev only governor can call this function
     * @param _index uint256
     * @return true
     */
    function nullify(uint256 _index) external onlyGovernor returns(bool) {
        permissionOrder[_index].nullify = true;
        return true;
    }

    /**
     * @notice enableTimelock
     * @notice function to disable timelock
     * @dev only governor can call this function
     * @dev set timelockEnabled to true
     */
    function enableTimelock() external onlyGovernor {
        require(!timelockEnabled, "SCT Treasury: timelock already enabled");
        timelockEnabled = true;
        emit ChangedTimelock(true);
    }

    /**
     * @notice disableTimelock
     * @notice function to disable timelock
     * @dev only governor can call this function
     * @dev if onChainGovernanceTimelock is less or equal than block number this fucntion set timelockEnabled to false
     * @dev if onChainGovernanceTimelock is more than block number this function set new onChainGovernanceTimelock
     */
    function disableTimelock() external onlyGovernor {
        require(timelockEnabled, "SCT Treasury: timelock already disabled");
        if (onChainGovernanceTimelock <= block.number) {
            timelockEnabled = false;
            emit ChangedTimelock(false);
        } else {
            onChainGovernanceTimelock = block.number + (blocksNeededForOrder * 10);
            emit SetOnChainGovernanceTimelock(onChainGovernanceTimelock);
        }
    }

    /**
     * @notice baseSupply
     * @notice view function that returns SCT total supply
     * @return uint256
     */
    function baseSupply() external view returns (uint256) {
        return SCT.totalSupply();
    }

    /**
     * @notice onERC1155Received
     * @notice virtual function to allow contract accept ERC1155 tokens
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @notice onERC1155BatchReceived
     * @notice virtual function to allow contract accept ERC1155 tokens
     */
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}