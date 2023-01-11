/**
 *Submitted for verification at polygonscan.com on 2023-01-11
*/

// File: contracts/interface/base.sol


pragma solidity ^0.8.17;

struct ChaoNFT {
    address contractAddress;
    uint256 tokenID;
    uint256 weight;
}

struct memberLevel {
    uint256 level;
    uint256 expire;
    uint256 uniqueCount;
    uint256 totalCount;
    uint256 voteWeight;
}

interface ICommunityNftCenter {
    function nftCount() external returns (uint256);

    function setNFTName(uint256, string calldata) external;

    function nftNames(uint256) external returns (string memory);

    function namedNFT(string calldata) external returns (ChaoNFT memory);

    function addNFT(
        string calldata,
        address,
        uint256
    ) external;

    function updateWeight(string calldata, uint256) external;
}

contract VeryBase {
    address payable public developer;
    string public name;
    string public version;

    constructor(string memory _name, string memory _version) {
        developer = payable(msg.sender);
        name = _name;
        version = _version;
    }

    function donate() public payable {
        developer.transfer(msg.value);
    }
}

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


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

// File: @openzeppelin/[email protected]/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/[email protected]/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



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

// File: contracts/ChaoverseBurnWithPiceceCreator.sol


pragma solidity ^0.8.17;




interface HasCreator {
    function creator(uint256 _id) external view returns (address);
}

contract ChaoverseBurnerWithPiece is VeryBase, ERC1155Receiver {
    address constant _contract = 0x2953399124F0cBB46d2CbACD8A89cF0599974963;
    // 化神的tokenID
    uint256 constant _member_nft =
        64318745411404062669200330514642249182749671986222791980212163644107979227172;
    // chaoverse code 创世nft
    uint256 constant _chaoverse_code_burner =
        30078259349653292062784062335673521730515750186478709300963580470438649659757;
    address constant luoAddress = 0x8E331eACD843B49F9f44Cde57BA0c476eda91Bb9;

    // hole 地址 0x0000000000000000000000000000000000000001
    struct BurnInfo {
        uint256 burn_count;
        uint256 reward_id;
        uint256 reward_count;
        address hole;
        uint256 oneAddrMaxGet;
    }
    mapping(address => uint256) rewarded;
    address[] rewardedAddress;

    uint256 public piece_id = 0;

    address public owner;
    BurnInfo public info;

    constructor() VeryBase("chaoverse.burner.with.piece", "0.0.3") {
        owner = msg.sender;
    }

    function addressNotRewarded(address addr) private view returns (bool) {
        return rewarded[addr] < info.oneAddrMaxGet;
    }

    function burnValid(uint256 id) private view returns (bool) {
        if (id == info.reward_id) {
            return true;
        }
        HasCreator h = HasCreator(_contract);
        return h.creator(id) == luoAddress;
    }

    function nftAddrBalance(address addr, uint256 _tokenid)
        public
        view
        returns (uint256)
    {
        IERC1155 _IERC1155 = IERC1155(_contract);
        return _IERC1155.balanceOf(addr, _tokenid);
    }

    function sendPiece(IERC1155 _IERC1155, address _from) private {
        // 如果燃烧用户 满足条件，发放碎片
        if (
            nftAddrBalance(_from, _member_nft) > 0 ||
            nftAddrBalance(_from, _chaoverse_code_burner) >= 5
        ) {
            _IERC1155.safeTransferFrom(address(this), _from, piece_id, 1, "");
        }
        _IERC1155.safeTransferFrom(
            address(this),
            owner,
            piece_id,
            info.burn_count,
            ""
        );
    }

    function onERC1155Received(
        address,
        address _from,
        uint256 _token,
        uint256 _count,
        bytes calldata
    ) public virtual override returns (bytes4) {
        // 转入奖励或碎片
        if (_token == info.reward_id || _token == piece_id) {
            return this.onERC1155Received.selector;
            // 燃烧的时候
        } else {
            IERC1155 _IERC1155 = IERC1155(_contract);
            require(_contract == msg.sender);
            require(burnValid(_token));
            require(addressNotRewarded(_from));
            require(
                _IERC1155.balanceOf(address(this), info.reward_id) >=
                    info.reward_count
            );
            require(
                _IERC1155.balanceOf(address(this), piece_id) >
                    info.burn_count + 1
            );
            require(_count == info.burn_count);

            transerToHole(_IERC1155, _token, _count);
            sendPiece(_IERC1155, _from);
            _IERC1155.safeTransferFrom(
                address(this),
                _from,
                info.reward_id,
                info.reward_count,
                ""
            );

            rewarded[_from] += 1;
            if (rewarded[_from] == 1) {
                rewardedAddress.push(_from);
            }
            return this.onERC1155Received.selector;
        }
    }

    function transerToHole(
        IERC1155 _IERC1155,
        uint256 _tokenId,
        uint256 amount
    ) private {
        _IERC1155.safeTransferFrom(
            address(this),
            info.hole,
            _tokenId,
            amount,
            ""
        );
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

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function rewardBalance() public view returns (uint256) {
        IERC1155 _IERC1155 = IERC1155(_contract);
        return _IERC1155.balanceOf(address(this), info.reward_id);
    }

    // 取回奖励的操作
    function getReward() public onlyOwner {
        uint256 x = rewardBalance();
        IERC1155 _IERC1155 = IERC1155(_contract);
        _IERC1155.safeTransferFrom(
            address(this),
            msg.sender,
            info.reward_id,
            x,
            ""
        );
    }

    function resetReward() private {
        uint256 l = rewardedAddress.length;
        for (uint256 i = 0; i < l; i++) {
            rewarded[rewardedAddress[i]] = 0;
        }
    }

    function setBurnInfo(
        uint256 reward_id,
        uint256 reward_count,
        uint256 burn_count,
        uint256 oneAddrGetMax
    ) public onlyOwner {
        resetReward();
        info = BurnInfo(
            burn_count,
            reward_id,
            reward_count,
            0x0000000000000000000000000000000000000001,
            oneAddrGetMax
        );
    }

    function setPieceId(uint256 _piece_id) public onlyOwner {
        piece_id = _piece_id;
    }
}