// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title NFT Carbon Reciever Contraact
 * @notice Registration, Claim and Retirement contract for First Carbon
 * @author First Carbon
 */
/*
 * @dev IERC1155: carbon credit backed NFT  
 */

interface IERC1155 {

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) external;

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;


    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address _owner, uint256 _id) external returns (uint256);

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);
}


enum RequestType {None, Retirement, Claim }
enum Status { NotStarted, Requested, Complete, Cancelled }

/**
* @dev Status of Retitrememnt or claim when an claim or retiterement has been initiated
*/
struct RetirementStatus {
    address contractAddress; // address of the contract to retire
    RequestType requestType; // None, Retirement, Claim
    Status status; // NotStarted, Requested, Complete, Cancelled
    address user; // address of the retirer
    uint lastUpdated; // last update block
    uint id; // id of credits to retire
    uint quantity; // quantity of credits to be retired or claimed
    string offchainId; // offchain reference to the retirement (e.g. serial number)
    string accountNumber; // account number of user where credits should be transfered to if claim
}

/**
* @dev Retirement details for a given carbon credit backed nft 
*/
struct CreditContractRetirement {
    address retirementContractAddress; // address of the retirement NFT contract
    uint retirementTokenId; // token id of the retirement NFT
    uint registryId; // the registry for the credits
    uint vintage; // vintage Year
    string projectId; // ID of the project on the registry
    string country; // Country where the project took place
}

contract CarbonReceiver is ERC1155Receiver,AccessControl,ReentrancyGuard {

    /**
     * @notice if the contract retirements or claims are paused
     */
    bool public receiveDisabled = false;

    /*
     * @notice mapping for a given active credit NFT to it's retirement instruction
     * @param creditAddress - carbon credit NFT address
     * @param creditTokenId - carbon credit tokenId
     * @returns CreditContractRetirement - the retirement instructions for that active carbon NFT
     */
    mapping(address =>
        mapping(uint => CreditContractRetirement)) public retirementInstructions;


    /*
    * @dev counter to ensure the number of admins never gets to 0 
    */
    uint public adminCount = 0;

    /**
     * @notice running number keep track of retirement requests on chain
     */
    uint public retirementCount = 0;

    /*
     * @notice mapping of retirement request ID to retirement status
     * @param retirementId - carbon credit tokenId
     * @return RetirementStatus -Information about the status of the retirement
     */
    mapping(uint => RetirementStatus) public retirementRequests;

    /*
     * @notice verifier ids to sting value
     * @param registryId - int id of the registry
     * @return registryName - string name of the registry (e.g. Verra)
     */
    mapping(uint => string) public registryNames;

    /*
     * @notice track the total number of burns for an address for use in leader board
     * @param userAddress - address that initiated retirement
     * @return countRetirement - total count of retirements for that user
     */
    mapping(address => uint) public addressRetirementCount;

    /*
     * @notice track the burn for a user on specific contracts
     * @param userAddress - address that initiated retirement
     * @param creditAddress - carbon credit NFT address
     * @param creditTokenId - carbon credit tokenId
     * @return countRetirement - total count of retirements for that user
     */
    mapping(address =>
        mapping(address =>
            mapping(uint => uint))) public addressContractRetirementCount;

    /**
     * @notice role for users with power to verify offchain consumption - can call finaliseOffchainRequest
    */
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    /**
     * @notice role for users with power add retirement instructions -  can call addCredit
    */
    bytes32 public constant CONFIGURATION_ROLE = keccak256("CONFIGURATION_ROLE");

    /**
    * @dev Fire when an active credits retirement information has been added to the contract
    * @param user - address making the configuration change
    * @param activeContractAddress - active carbon credit NFT address
    * @param activeTokenId - active carbon credit tokenId
    * @param retiredContractAddress - corresponding retired NFT address
    * @param retiredTokenId - corresponding retired NFT tokenId
    */
    event RetirementInstructionsAdded(address indexed user, address indexed activeContractAddress, uint activeTokenId,
        address indexed retiredContractAddress, uint retiredTokenId);

    /**
    * @dev Fire when a carbon NFT retirement request has been initiated
    * @param user - address initiating the retirement
    * @param carbonContract - active carbon credit NFT address being retired
    * @param id - active carbon credit tokenId
    * @param quantity - number of credits being retired
    * @param retirementStatusId - the id of the entry into the status mapping (retirementRequests)
    */
    event RetirementRequestedAccepted(address indexed user, address indexed carbonContract, uint indexed id, uint quantity,uint retirementStatusId);

    /**
    * @dev Fire when a carbon NFT retirement request has been completed
    * @param verifier - address of the verifier that retired on registry
    * @param user - user that initiated the retirement
    * @param retirementStatusId - the id of the entry into the status mapping (retirementRequests)
    * @param offchainId - id of the retirement on the registry
    */
    event RetirementRequestedCompleted(address verifier,address indexed user, uint retirementStatusId, string offchainId);

    /*
    * @dev Fire when a carbon NFT claim request has been initiated
    * @param user - address initiating the retirement
    * @param carbonContract - active carbon credit NFT address being retired
    * @param tokenId - active carbon credit tokenId
    * @param quantity - number of credits being claimed
    * @param registry - registry id of the credit being claimed
    * @param projectId - registry project id of the credit being claimed
    * @param vintage - vintage of credit being retired
    * @param accountNumber - registry account number where the claimed credits should land
    * @param retirementStatusId - the id of the entry into the status mapping (retirementRequests)
    */
    event ClaimRequestAccepted(
        address indexed user,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 quantity,
        uint256 registry,
        string indexed projectId,
        uint256 vintage,
        string accountNumber,
        uint retirementStatusId);

    /**
    * @dev Fire when a carbon NFT claim request has been completed
    * @param verifier - address of the verifier that transferred the credit on the registry
    * @param user - user that initiated the claim
    * @param retirementStatusId - the id of the entry into the status mapping (retirementRequests)
    * @param offchainId - id of the retirement on the registry
    * @param newStatus - Was the offchain request complete or cancelled
    */
    event ClaimRequestedCompleted(address verifier,address indexed user,
    uint retirementStatusId, string offchainId, string indexed newStatus);

    /**
    * @dev Fire when contract is disabled or re-enabled QSP-8
    * @param setDisabled - boolean for if the contract is set to disabled
    * @param adminAddress - address of the admin enabling or disabling claim
    */
    event ChangeContractDisabled( bool setDisabled,address adminAddress);

    /*
    * @dev initialize a standard ERC1155Receiver contract
    *      grant deployer address DEFAULT_ADMIN_ROLE, VERIFIER_ROLE, CONFIGURATION_ROLE
    */
    constructor() public
    {
         _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
         _setupRole(VERIFIER_ROLE, msg.sender);
         _setupRole(CONFIGURATION_ROLE, msg.sender);
         adminCount+=1;
    }

    /**
    * @notice Add a registry to the contract
    * @param registryId - int id of the registry
    * @param registryName - string name of the registry
    */
    function addRegistry(uint registryId,string memory registryName) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(registryNames[registryId]).length == 0,"Cannot overwrite registry"); 
        registryNames[registryId] = registryName;
    }


    /**
    * @notice add a credit to the contract so that it can be retired or claimed on chain
    *    retired credits need to have been sent to the contract ahead of registering the active credits 
    * @param _contractAddress - active carbon credit ERC1155 contract address
    * @param _creditTokenId - active carbon token id on the ERC1155 contract
    * @param _retirementcontractAddress - retired carbon credit ERC1155 contract address
    * @param _retirementCreditTokenId - retired carbon token id on the ERC1155 contract
    * @param _registryId - registry id the active credit belongs to from registryNames
    * @param _vintage - vintage for the active credit being added
    * @param _projectId - project ID on the registry
    * @param _country - string country of the credit
    */
    function addCredit(
        address _contractAddress,
        uint _creditTokenId,
        address _retirementcontractAddress,
        uint _retirementCreditTokenId,
        uint _registryId,
        uint _vintage,
        string memory _projectId,
        string memory _country
        ) public onlyRole(CONFIGURATION_ROLE) nonReentrant {
            require(_contractAddress != address(0),"Cannot set contract contract to null address"); 
            require(_retirementcontractAddress != address(0),"Cannot set retirement contract to null address");
            require(retirementInstructions[_contractAddress][_creditTokenId].retirementContractAddress == address(0),
            "Contract and token Id already set");
            require(retirementInstructions[_retirementcontractAddress][_retirementCreditTokenId].retirementContractAddress == address(0),
            "Retirement contract cannot be the same as an active credit");

            // create new retirement mapping for carbon NFT
            CreditContractRetirement storage newContract = retirementInstructions[_contractAddress][_creditTokenId];
            newContract.retirementContractAddress = _retirementcontractAddress;
            newContract.retirementTokenId = _retirementCreditTokenId;
            newContract.registryId = _registryId;
            newContract.vintage = _vintage;
            newContract.projectId = _projectId;
            newContract.country = _country;


            IERC1155 retirementNftContract = IERC1155(_retirementcontractAddress);
            require(retirementNftContract.balanceOf(address(this),_retirementCreditTokenId) > 0, "Please send contract the retired version");
            require(bytes(registryNames[_registryId]).length != 0, "No registry with that Id");

            emit RetirementInstructionsAdded(msg.sender, _contractAddress, _creditTokenId, _retirementcontractAddress, _retirementCreditTokenId);
    }


    /*
    * @notice main retirement function
    *    Approval from the callor is required on the carbonContract before calling this function
    *    active carbon credit is burnt
    *    retired credit nft is transferred to the user
    *    retirement request is initiated for verifiers to retire the credit on the registry
    * @param carbonContract - active carbon credit ERC1155 contract address being retired
    * @param _nftId - active carbon token id on the ERC1155 contract being retired
    * @param _nftQuantity - number of credits being retired
    */
    function retireActiveCredit(
        address carbonContract,
        uint256 _nftId,
        uint256 _nftQuantity
    ) public  nonReentrant {
        require(!receiveDisabled, "disabled");
        address retireAddress = retirementInstructions[carbonContract][_nftId].retirementContractAddress;
        uint retireTokenId = retirementInstructions[carbonContract][_nftId].retirementTokenId;
        require(retireAddress != address(0), "must have retirement instructions for this contract and token");

        IERC1155 activeNftContract = IERC1155(carbonContract);
        IERC1155 retiredNftContract = IERC1155(retireAddress);

        require(retiredNftContract.balanceOf(address(this),
            retireTokenId)
            >= _nftQuantity,
            "must have enough retired NFTs on the contract to complete the redemption");

        // Create new retirement request
        RetirementStatus memory newRetirement;
        newRetirement.contractAddress = carbonContract;
        newRetirement.user = msg.sender;
        newRetirement.requestType = RequestType.Retirement;
        newRetirement.id = _nftId;
        newRetirement.quantity = _nftQuantity;
        newRetirement.status = Status.Requested;
        newRetirement.lastUpdated = block.number;

        retirementRequests[retirementCount] = newRetirement;
        emit RetirementRequestedAccepted(msg.sender, carbonContract, _nftId,_nftQuantity,retirementCount);

        // update counters
        addressRetirementCount[msg.sender] += _nftQuantity;
        addressContractRetirementCount[msg.sender][carbonContract][_nftId] += _nftQuantity;

        retirementCount += 1;

        // send through the credits to redeem to the contract for burning
        activeNftContract.burn(msg.sender,_nftId,_nftQuantity);

        // send back the retired NFT
        retiredNftContract.safeTransferFrom(address(this),msg.sender,
            retireTokenId,
            _nftQuantity,""
            );
    }

    function setReceiveDisabled(bool _val) public onlyRole(DEFAULT_ADMIN_ROLE) {
        receiveDisabled = _val;
        emit ChangeContractDisabled(_val,msg.sender);
    }


    /*
    * @notice claim the underlying NFT into a registry account using this function
    *    approval from the callor is required on the carbonContract before calling this function
    *    active carbon credit is transferred to the contract to be burnt once the offchain transfer is complete
    *    Claim request is initiated for verifiers to transfer the credit on the registry to the specified address
    * @param carbonContract - active carbon credit ERC1155 contract address being retired
    * @param _nftId - active carbon token id on the ERC1155 contract being retired
    * @param _nftQuantity - number of credits being retired
    * @param accountNumber - The registry account to which the credit is being transferred offline
    */
    function claimActiveCredit(
        address carbonContract,
        uint256 _nftId,
        uint256 _nftQuantity,
        string memory accountNumber
    ) public nonReentrant {
        require(!receiveDisabled, "disabled");

        // look up retirement instructions
        CreditContractRetirement storage instruction = retirementInstructions[carbonContract][_nftId];
        require(instruction.retirementContractAddress != address(0),
         "must have retirement instructions for this contract and token");

        // Create new retirement request
        RetirementStatus memory newClaim;
        newClaim.contractAddress = carbonContract;
        newClaim.user = msg.sender;
        newClaim.requestType = RequestType.Claim;
        newClaim.id = _nftId;
        newClaim.quantity = _nftQuantity;
        newClaim.status = Status.Requested;
        newClaim.lastUpdated = block.number;
        newClaim.accountNumber = accountNumber;
        retirementRequests[retirementCount] = newClaim;

        // get information about credit to help validator
        uint256 _registryId = instruction.registryId;
        uint256 _vintage = instruction.vintage;
        string memory _projectId = instruction.projectId;

        emit ClaimRequestAccepted(msg.sender, carbonContract, _nftId,_nftQuantity,
        _registryId, _projectId, _vintage,accountNumber, retirementCount);

        retirementCount+=1;

        // transfer the active to the contract to be burned upon completion of the transfer
        IERC1155 activeNftContract = IERC1155(carbonContract);
        activeNftContract.safeTransferFrom(msg.sender,address(this),_nftId,_nftQuantity,'');

    }


    /*
    * @notice verifier can confirm an off chain action has been performed and complete the request
    *    closing a retirement request, the verifier will provide the id of the retired credits from the registry
    *    closing a claim request, the verifier will provide the registry credit number of the transferrred credits
    * @param requestId - the request id to be closed
    * @param offchainId - the retirement or credit id that results from the offchain registry action
    */
    function finaliseOffchainRequest(uint256 requestId, string memory offchainId) public onlyRole(VERIFIER_ROLE) nonReentrant {

        require(bytes(offchainId).length > 0, "offchainId must not be blank");
        
        // look up request
        RetirementStatus storage openRequest = retirementRequests[requestId];

        require(bytes(openRequest.offchainId).length == 0, "Cannot have already been retired offchain");
        require(openRequest.requestType == RequestType.Retirement
         || openRequest.requestType == RequestType.Claim ,
        "Request id ID must be for a claim or redemption");
        require(openRequest.status == Status.Requested,
        "Must not have already completed a retirement or claim for this requestID");

        // change the status of the request
        retirementRequests[requestId].status = Status.Complete;
        retirementRequests[requestId].lastUpdated = block.number;
        retirementRequests[requestId].offchainId = offchainId;

        if (openRequest.requestType == RequestType.Retirement){
            // Case of a retirement
            emit RetirementRequestedCompleted(msg.sender,openRequest.user,requestId, offchainId);
        } else if (openRequest.requestType == RequestType.Claim){
            // Case of a claim
            address carbonContract = openRequest.contractAddress;
            uint id = openRequest.id;
            uint quantity = openRequest.quantity;

            address retirementContractAddress = retirementInstructions[carbonContract][id].retirementContractAddress;
            uint retirementId = retirementInstructions[carbonContract][id].retirementTokenId;


            // check that we can burn the retirement nfts as there will be no active nft tie
            IERC1155 retirementNftContract = IERC1155(retirementContractAddress);
            require(retirementNftContract.balanceOf(address(this),retirementId) >= quantity,
            "Contract must have adiquate number of retire credit to be burnt");

            emit ClaimRequestedCompleted(msg.sender,openRequest.user,requestId, offchainId,"Complete");

            // retire the active credits after off chain transfer
            IERC1155 activeNftContract = IERC1155(carbonContract);
            activeNftContract.burn(address(this),id,quantity);

            // destroy the retired credit NFTs
            retirementNftContract.burn(address(this),retirementId,quantity);
        }

    }

    /*
    * @notice verifier can cancel a claim request in the event that 
    *    delivery cannot be made (incorrect account number entered, closed account, etc.)
    *    when the claim is cancelled the claim status is set to "cancelled" and active nfts 
    *    are returned to the claim request address
    * @param requestId - the request id to be closed
    */
    function cancelOffchainRequest(uint256 requestId) public onlyRole(VERIFIER_ROLE) nonReentrant {

        // look up request
        RetirementStatus storage openRequest = retirementRequests[requestId];

        require(bytes(openRequest.offchainId).length == 0, "Cannot have already been claimed offchain");
        require(openRequest.requestType == RequestType.Claim, "Request ID must be for a claim");
        require(openRequest.status == Status.Requested,
        "Must not have already completed a retirement or claim for this requestID");

        emit ClaimRequestedCompleted(msg.sender,openRequest.user,requestId, "","Cancelled");

        // change the status of the request
        retirementRequests[requestId].status = Status.Cancelled;
        retirementRequests[requestId].lastUpdated = block.number;
        retirementRequests[requestId].offchainId = "";

        address carbonContract = openRequest.contractAddress;
        uint id = openRequest.id;
        uint quantity = openRequest.quantity;
        address userAddress = openRequest.user;

        // check that we have enough credits to reverse the claim
        IERC1155 activeNftContract = IERC1155(carbonContract);
        require(activeNftContract.balanceOf(address(this),id) >= quantity,
        "Contract must have adiquate number of active credit to return to the user");

        // Send the active credits back to the claimant
        activeNftContract.safeTransferFrom(address(this),userAddress,id,quantity,'');
    }


    /*
    * @notice just in case function to transfer accidental sends of NFTs, or cases where NFT holders ask for a claim but do not 
    *    have the correct registry account
    * @param address - address to sweep the NFTs to
    * @param contractAddress - contract of the NFT to be swept
    * @param tokenId - tokenid of the credits to be swept
    * @param value - number of NFTs to sweep
    */
    function sweepNFT(address to,address contractAddress,uint tokenId,uint value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC1155 nftContract = IERC1155(contractAddress);
        nftContract.safeTransferFrom(address(this),to,tokenId,value,'');
    }



    
    /**
     * @dev Grants `role` to `account`. Add one to the count of admins if it is the role being set
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE){
            require(hasRole(DEFAULT_ADMIN_ROLE,account) == false,"Address already has admin role");
            adminCount +=1;
        }
        super.grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account` and decrements admin count by 1 if DEFAULT_ADMIN_ROLE 
     * is the account being removed
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE){
            require(hasRole(DEFAULT_ADMIN_ROLE,account) == true,"Address is not admin");
            require(adminCount > 1, "Contract must have at least one admin remaining");
            adminCount -=1;
        }

        super.revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account and decrements admin count by 1 if 
     * DEFAULT_ADMIN_ROLE is the account being removed
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
    function renounceRole(bytes32 role, address account) public virtual override {
        if (role == DEFAULT_ADMIN_ROLE){
            require(hasRole(DEFAULT_ADMIN_ROLE,account) == true,"Address is not admin");
            require(adminCount > 1, "Contract must have at least one admin remaining");
            adminCount -=1;
        }

        super.renounceRole(role, account);
    }

    /*
    * @dev: Simple implementation of `ERC1155Receiver` that will allow a contract to receive and hold ERC1155 tokens.
    */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override( ERC1155Receiver,AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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