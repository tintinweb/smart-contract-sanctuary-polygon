// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Interface/IWhitelist.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
contract Whitelist is IWhitelist {

    uint256 public constant BATCH_MAX_NUM = 200;

    address public governanceAccount;
    address public whitelistAdmin;
    address public airdropAddress;
    IERC721 public qatarWorldCup; 

    // mapping(address => uint256) private _whitelisteds;
    mapping(address => mapping(uint256 => WhitelistInfo)) private _whitelistDetail;
    mapping(address => WhitelistInfo[]) private _listWhitelist;
    constructor(IERC721 _qatar, address _airdropAddress ) {
        governanceAccount = msg.sender;
        whitelistAdmin = msg.sender;
        airdropAddress = _airdropAddress;
        qatarWorldCup =  _qatar;
    }

    modifier onlyBy(address account) {
        require(
            msg.sender == account,
            "Whitelist: sender unauthorized"
        );
        _;
    }

    function addWhitelisted(address account, uint256 amount, uint256 tokenId)
    external
    override
    onlyBy(whitelistAdmin)
    {
        _addWhitelisted(account, amount, tokenId);
    }

    function removeWhitelisted(address account, uint256 tokenId)
    external
    override
    onlyBy(whitelistAdmin)
    {
        _removeWhitelisted(account, tokenId);
    }

    function addWhitelistedBatch(
        address[] memory accounts,
        uint256[] memory amounts,
        uint256[] memory tokenId
    ) external override onlyBy(whitelistAdmin) {
        require(accounts.length > 0, "Whitelist: empty");
        require(
            accounts.length <= BATCH_MAX_NUM,
            "Whitelist: exceed max"
        );
        require(
            amounts.length == accounts.length && accounts.length == tokenId.length,
            "Whitelist: different length"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _addWhitelisted(accounts[i], amounts[i], tokenId[i]);
        }
    }

    function removeWhitelistedBatch(address[] memory accounts, uint256[] memory tokenIds)
    external
    override
    onlyBy(whitelistAdmin)
    {
        require(accounts.length > 0, "Whitelist: empty");
        require(
            accounts.length <= BATCH_MAX_NUM,
            "Whitelist: exceed max"
        );
        require(
            accounts.length == tokenIds.length,
            "Whitelist: different length"
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            require(qatarWorldCup.ownerOf(tokenIds[i]) == accounts[i], "Whitelist: Invalid owner token");
            _removeWhitelisted(accounts[i], tokenIds[i]);
        }
    }

    function setGovernanceAccount(address account)
    external
    override
    onlyBy(governanceAccount)
    {
        require(account != address(0), "Whitelist: zero account");

        governanceAccount = account;
    }

    function setWhitelistAdmin(address account)
    external
    override
    onlyBy(governanceAccount)
    {
        require(account != address(0), "Whitelist: zero account");
        whitelistAdmin = account;
    }

    function updateClaimed(address account, uint256 tokenId)
    external
    override
    onlyBy(airdropAddress)
    {
        require(account != address(0), "Whitelist: zero account");
        _whitelistDetail[account][tokenId].isClaimed = true;

        WhitelistInfo[] memory _whitelists = _listWhitelist[account];
        for(uint256 i = 0; i < _whitelists.length; i++){
            _listWhitelist[account][i].isClaimed = true; 
        }
    }

    function isWhitelisted(address account, uint256 tokenId)
    public
    view
    override
    returns (bool isWhitelisted_)
    {
        require(account != address(0), "Whitelist: zero account");
        isWhitelisted_ = _whitelistDetail[account][tokenId].isWhitelist;
    }


    function isWhitelistedClaim(address account, uint256 tokenId)
    public
    view
    override
    returns (bool isWhitelistClaim_){
        require(account != address(0), "Whitelist: zero account");
        isWhitelistClaim_ = _whitelistDetail[account][tokenId].isClaimed;
    }

    function getListWhitelist()
    public
    view
    override
    returns (WhitelistInfo[] memory _whitelistInfo){
        address _sender = msg.sender;
        _whitelistInfo = _listWhitelist[_sender];
    }

    function whitelistedAmountFor(address account, uint256 tokenId)
    public
    view
    override
    returns (uint256 whitelistedAmount)
    {
        require(account != address(0), "Whitelist: zero account");
        require(qatarWorldCup.ownerOf(tokenId) == account, "Whitelist: Invalid owner token");
        whitelistedAmount = _whitelistDetail[account][tokenId].amount;
    }

    function _addWhitelisted(address account, uint256 amount, uint256 tokenId) internal {
        require(account != address(0), "Whitelist: zero account");
        require(amount > 0, "Whitelist: zero amount");
        require(_whitelistDetail[account][tokenId].amount == 0, "Whitelist: already whitelisted");
        require(qatarWorldCup.ownerOf(tokenId) == account, "Whitelist: Invalid owner token");
        WhitelistInfo memory whitelistInfo = WhitelistInfo(amount, tokenId, true, false);
        // _whitelisteds[account] = amount;
        _whitelistDetail[account][tokenId] = whitelistInfo;
        _listWhitelist[account].push(whitelistInfo);

        emit WhitelistedAdded(account, amount, tokenId);
    }



    function _removeWhitelisted(address account, uint256 tokenId) internal {
        require(account != address(0), "Whitelist: zero account");
        // require(
        //     _whitelisteds[account] > 0,
        //     "Whitelist: not whitelisted"
        // );
        require(
            _whitelistDetail[account][tokenId].amount > 0,
            "Whitelist: not whitelisted"
        );
        // _whitelisteds[account] = 0;
        delete _whitelistDetail[account][tokenId];
        emit WhitelistedRemoved(account, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IWhitelist {
    struct WhitelistInfo {
        uint256 tokenId;
        uint256 amount;
        bool isWhitelist;
        bool isClaimed;
    }

    function addWhitelisted(address account, uint256 amount, uint256 tokenId) external;

    function removeWhitelisted(address account, uint256 tokenId) external;

    function addWhitelistedBatch(
        address[] memory accounts,
        uint256[] memory amounts,
        uint256[] memory tokenId
    ) external;

    function removeWhitelistedBatch(address[] memory accounts, uint256[] memory tokenIds) external;

    function setGovernanceAccount(address account) external;

    function setWhitelistAdmin(address account) external;

    function updateClaimed(address account,uint256 tokenId) external;

    function isWhitelisted(address account, uint256 tokenId)
    external
    view
    returns (bool isWhitelisted_);

    function isWhitelistedClaim(address account, uint256 tokenId)
    external
    view
    returns (bool isWhitelistClaim_);

    function whitelistedAmountFor(address account, uint256 tokenId)
    external
    view
    returns (uint256 whitelistedAmount);

    function getListWhitelist()
    external
    view
    returns (WhitelistInfo[] memory _whitelistInfo);

    event WhitelistedAdded(address indexed account, uint256 amount, uint tokenId);
    event WhitelistedRemoved(address indexed account, uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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