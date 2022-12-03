//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../helpers/dataStructures/StakeData.sol";
import "../interfaces/IWonderGameCharacterInventory.sol";
import "./WonderStakeAccessControl.sol";
import {TokenTypes} from "../helpers/TokenTypes.sol";
import "../interfaces/IRaffle.sol";

contract WonderStake is IERC721Receiver, WonderStakeAccessControl, StakeData {
    IWonderGameCharacterInventory public wonderland;

    uint256 public stakeLimitInSecs = 0; //make this immutable in production

    // tokenId => stake details for that token id
    mapping(uint256 => NftStakeDetails) public nftStakeDetails;

    // user => tokenId list
    mapping(address => uint256[]) public userStakeNfts;

    // tokenId => index,returns the index of staked token id in the userStakedNfts
    mapping(uint256 => uint256) public tokenIdToIndex;

    mapping(uint256 => uint256) public slopes;
    mapping(uint256 => uint256) public bias;

    IRaffle public raffle;
    uint256 public rewardPeriod; //make this immutable in production

    constructor(
        IWonderGameCharacterInventory _wonderland,
        uint256 _nonCardSlope,
        uint256 _nonCardBias,
        uint256 _cardSlope,
        uint256 _cardBias,
        IRaffle _raffle,
        uint256 _rewardPeriod
    ) {
        setWonderland(_wonderland);
        slopes[TokenTypes.ALICE] = slopes[TokenTypes.QUEEN] = _nonCardSlope;
        bias[TokenTypes.ALICE] = bias[TokenTypes.QUEEN] = _nonCardBias;
        slopes[TokenTypes.CARD] = _cardSlope;
        bias[TokenTypes.CARD] = _cardBias;
        raffle = _raffle;
        rewardPeriod = _rewardPeriod;
    }

    // function setRewardPeriod(uint256 period) public onlyRole(OWNER_ROLE) {
    //     //remove this function in production
    //     rewardPeriod = period;
    // }

    function setSlope(uint256 _type, uint256 _slope)
        public
        onlyRole(OWNER_ROLE)
    {
        slopes[_type] = _slope;
    }

    function setBias(uint256 _type, uint256 _bias) public onlyRole(OWNER_ROLE) {
        bias[_type] = _bias;
    }

    function setWonderland(IWonderGameCharacterInventory _wonderland)
        public
        onlyRole(OWNER_ROLE)
    {
        wonderland = _wonderland;
    }

    function setRaffle(IRaffle _raff) public onlyRole(OWNER_ROLE) {
        raffle = _raff;
    }

    function setStakePeriod(uint256 timeInSeconds) public onlyRole(OWNER_ROLE) {
        //remove this in production
        stakeLimitInSecs = timeInSeconds;
    }

    function getUserStakedNfts(address _user, uint256 _index)
        external
        view
        returns (uint256[] memory, uint256)
    {
        uint256 start = _index * 20;
        uint256 end = start + 19;
        uint256 total = userStakeNfts[_user].length;
        if (start > total) {
            start = end = 0;
        }
        if (end > total) {
            end = total - 1;
        }

        uint256[] memory nfts = new uint256[](end - start + 1);
        for (uint256 i = start; i <= end; i++) {
            nfts[i] = userStakeNfts[_user][i];
        }
        return (nfts, total);
    }

    function getUserRaffles(
        address _user,
        uint256 _page,
        uint256 _index
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256
        )
    {
        uint256 start = _index * _page;
        uint256 end = start + (_page - 1);
        uint256 total = userStakeNfts[_user].length;
        if (start > total) {
            start = end = 0;
        }
        if (end > total) {
            end = total - 1;
        }

        uint256[] memory raffles = new uint256[](end - start + 1);
        uint256[] memory nfts = new uint256[](end - start + 1);
        for (uint256 i = start; i <= end; i++) {
            nfts[i] = userStakeNfts[_user][i];
            raffles[i] =
                _accruedRaffle(nfts[i]) -
                nftStakeDetails[nfts[i]].claimed;
        }
        return (nfts, raffles, total);
    }

    function getUserUnclaimedRaffles(address _user, uint256 _limit)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 start = 0;
        uint256 end = (_limit - 1);
        uint256 total = userStakeNfts[_user].length;
        if (end > total) {
            end = total - 1;
        }

        uint256[] memory raffles = new uint256[](end - start + 1);
        uint256[] memory nfts = new uint256[](end - start + 1);
        uint256 index;
        for (uint256 i = start; index <= end && i < total; i++) {
            uint256 tokenId = userStakeNfts[_user][i];
            uint256 unclaimedRaffle = _accruedRaffle(tokenId) -
                nftStakeDetails[tokenId].claimed;
            if (unclaimedRaffle > 0) {
                nfts[index] = tokenId;
                raffles[index] = unclaimedRaffle;
                index++;
            }
        }
        uint256[] memory finalraffles = new uint256[](index);
        uint256[] memory finalNFTs = new uint256[](index);
        for (uint256 i; i < index; i++) {
            finalraffles[i] = raffles[i];
            finalNFTs[i] = nfts[i];
        }
        return (finalNFTs, finalraffles);
    }

    function _character(uint256 _tokenId) internal pure returns (uint256) {
        uint256 mask = 0x00000000000000000000000000000000000000000000000FFFF0000;
        return (_tokenId & mask) >> 16;
    }

    function stake(uint256[] memory _tokenIds) external whenNotPaused {
        uint256 loop = _tokenIds.length;
        address user = msg.sender;
        for (uint256 i = 0; i < loop; i++) {
            _stakeNFT(_tokenIds[i], user);
        }
    }

    function _stakeNFT(uint256 _tokenId, address _user) internal {
        require(
            wonderland.ownerOf(_tokenId) == _user,
            "Stake NFT:Only owner can stake the token"
        );
        nftStakeDetails[_tokenId].owner = _user;
        nftStakeDetails[_tokenId].stakeStartTime = block.timestamp;
        uint256 arrayLength = userStakeNfts[_user].length;
        userStakeNfts[_user].push(_tokenId);
        tokenIdToIndex[_tokenId] = arrayLength;
        wonderland.safeTransferFrom(_user, address(this), _tokenId);
    }

    function unstake(uint256[] memory _tokenIds) external whenNotPaused {
        uint256 loop = _tokenIds.length;
        address user = msg.sender;
        for (uint256 i = 0; i < loop; i++) {
            uint256 tokenId = _tokenIds[i];
            require(
                nftStakeDetails[tokenId].owner == user,
                "Unstake NFT:only owner can unstake"
            );
            _burnRaffle(tokenId, user);
            _unstakeNft(tokenId, user);
        }
    }

    function _unstakeNft(uint256 _tokenId, address _user) internal {
        require(
            (block.timestamp - nftStakeDetails[_tokenId].stakeStartTime) >=
                stakeLimitInSecs,
            "Unstake NFT:Wait unstaking period"
        );
        delete nftStakeDetails[_tokenId];
        uint256[] storage userTokens = userStakeNfts[_user];
        _resetIndex(userTokens, tokenIdToIndex[_tokenId]);
        delete tokenIdToIndex[_tokenId];
        //        tokenIdToIndex[_tokenId] = userTokens.length - 1;
        wonderland.safeTransferFrom(address(this), _user, _tokenId);
    }

    function _burnRaffle(uint256 _tokenId, address _user) internal {
        uint256 claimed = nftStakeDetails[_tokenId].claimed;
        if (claimed > 0) {
            raffle.burnUserToken(_user, claimed);
        }
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) public view override returns (bytes4) {
        require(
            operator == address(this),
            "Direct Token transfer is not allowed"
        );
        // dont allow direct token receive
        return this.onERC721Received.selector;
    }

    function _resetIndex(uint256[] storage arr, uint256 index) internal {
        uint256 movedCharacter = arr[arr.length - 1];
        // update the value at that index
        arr[index] = movedCharacter;
        tokenIdToIndex[movedCharacter] = index;
        arr.pop();
    }

    function isTokenStaked(uint256 _tokenId) public view returns (bool) {
        uint256 stakeStart = nftStakeDetails[_tokenId].stakeStartTime;
        return stakeStart > 0 ? true : false;
    }

    function isStakedTokenOwnerOf(uint256 _tokenId, address _user)
        public
        view
        returns (bool)
    {
        if (isTokenStaked(_tokenId)) {
            address tokenOwner = nftStakeDetails[_tokenId].owner;
            return tokenOwner == _user ? true : false;
        } else {
            return false;
        }
    }

    function claimRaffle(uint256[] memory _tokenIds) external whenNotPaused {
        uint256 loop = _tokenIds.length;
        for (uint256 i = 0; i < loop; i++) {
            _claimRaffle(_tokenIds[i], msg.sender);
        }
    }

    function _claimRaffle(uint256 _tokenId, address _user) internal {
        require(
            nftStakeDetails[_tokenId].owner == _user,
            "Claim NFT:only owner can claim"
        );
        uint256 tokenRaffles = _accruedRaffle(_tokenId);
        uint256 unclaimed = tokenRaffles - nftStakeDetails[_tokenId].claimed;
        nftStakeDetails[_tokenId].claimed += unclaimed;
        raffle.claimRaffle(_user, unclaimed, "Nft Stake");
    }

    function accruedRaffle(uint256[] memory _tokenIds)
        external
        view
        returns (uint256)
    {
        uint256 loop = _tokenIds.length;
        uint256 total;
        for (uint256 i = 0; i < loop; i++) {
            total += (_accruedRaffle(_tokenIds[i]) -
                nftStakeDetails[_tokenIds[i]].claimed);
        }
        return total;
    }

    function _accruedRaffle(uint256 _tokenId) internal view returns (uint256) {
        uint256 stakedWeeks = getStakedWeeks(_tokenId);
        if (isTokenStaked(_tokenId) == true && stakedWeeks > 0) {
            return _calculateRaffle(_character(_tokenId), stakedWeeks);
        } else {
            return 0;
        }
    }

    function claimedRaffle(uint256[] memory _tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256 loop = _tokenIds.length;
        uint256 total;
        uint256[] memory claim = new uint256[](total);
        for (uint256 i = 0; i < loop; i++) {
            claim[i] = nftStakeDetails[_tokenIds[i]].claimed;
        }
        return claim;
    }

    function getStakedWeeks(uint256 _tokenId) public view returns (uint256) {
        uint256 startTime = nftStakeDetails[_tokenId].stakeStartTime;
        uint256 elapsedWeeks = startTime > 0
            ? ((block.timestamp - startTime) / rewardPeriod)
            : 0;
        return elapsedWeeks;
    }

    function _calculateRaffle(uint256 _tokenType, uint256 _n)
        internal
        view
        returns (uint256)
    {
        uint256 total;
        uint256 d;
        uint256 a;
        if (_tokenType == TokenTypes.ALICE || _tokenType == TokenTypes.QUEEN) {
            a = bias[TokenTypes.ALICE];
            d = slopes[TokenTypes.ALICE];
        } else if (
            _tokenType == TokenTypes.CLUBS_OF_RUNNER ||
            _tokenType == TokenTypes.DIAMOND_OF_ENERGY ||
            _tokenType == TokenTypes.SPADES_OF_MARKER ||
            _tokenType == TokenTypes.HEART_OF_ALL_ROUNDER
        ) {
            a = bias[TokenTypes.CARD];
            d = slopes[TokenTypes.CARD];
        } else {
            a = d = 0;
        }
        total = a + ((d * (_n - 1) * _n) / 2);
        return total;
    }

    function releaseNft(uint256[] memory _tokenId)
        external
        onlyRole(HANDLER_ROLE)
    {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            address holder = nftStakeDetails[_tokenId[i]].owner;
            delete nftStakeDetails[_tokenId[i]];
            wonderland.safeTransferFrom(address(this), holder, _tokenId[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

contract StakeData {
    struct NftStakeDetails{
        address owner;
        uint256 stakeStartTime;
        uint256 claimed;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IWonderGameCharacterInventory is IERC721 {
    function burn(uint256 _tokenId) external;
    function mint(address _to,uint256 _tokenId,string memory _secondaryTokenUri,uint256 _generation) external;
    function mintBatch(address _to, uint256[] memory _tokenIds,string[] memory _secondaryTokenUris, uint256 _generation) external;

}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract WonderStakeAccessControl is AccessControl {
    bytes32 internal constant OWNER_ROLE = 0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e;
    bytes32 internal constant HANDLER_ROLE = 0x8ee6ed50dc250dbccf4d86bd88d4956ab55c7de37d1fed5508924b70da11fe8b;

    //ToDo: change this owner address in mainnet
    address internal _owner_ = 0x698c514c49C3E1C4285fc87674De84cd56A72646;
    address internal handler = 0x698c514c49C3E1C4285fc87674De84cd56A72646;

    bool public isPaused;

    modifier whenNotPaused {
        require(!isPaused, "Wonder Game Character Inventory is paused");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner_);
        _setupRole(OWNER_ROLE, _owner_);
        _setupRole(HANDLER_ROLE,handler);
    }

    function pause() public onlyRole(OWNER_ROLE) {
        isPaused = true;
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        isPaused = false;
    }
}

pragma solidity ^0.8.0;

library TokenTypes{
    uint256  public constant UNKNOWN = 0x0000;
    uint256  public constant ALICE = 0x0001;
    uint256  public constant QUEEN = 0x0002;
    uint256  public constant CARD = 0x0003;
    uint256  public constant CLUBS_OF_RUNNER = 0x0013;
    uint256  public constant DIAMOND_OF_ENERGY = 0x0023;
    uint256  public constant SPADES_OF_MARKER = 0x0033;
    uint256  public constant HEART_OF_ALL_ROUNDER = 0x0043;

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRaffle is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function mint(address account,uint256 amount) external;
    function burnUserToken(address _user, uint256 _amount) external;
    function claimNftBurnRaffle() external;
    function claimRaffle(address _user, uint256 _amount, string memory _entity) external;
    function addNftBurnRaffle(address _user, uint256 _tokens) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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