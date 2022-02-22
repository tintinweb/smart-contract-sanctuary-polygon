/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

/**
 *Submitted for verification at polygonscan.com on 2021-10-07
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IERC721{
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

interface IERC1155{
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

contract NFTAirdrop {
    struct Airdrop721 {
        address tokenAddress;
        uint256 tokenId;
    }

    struct Airdrop1155 {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }
    //CONTADORES
    uint256 public nextAirdropId721;
    uint256 public nextAirdropId1155;
    //ADMIN
    address public admin;

    //Mapping de airdrops
    mapping(uint256 => Airdrop721) public airdrops721;
    mapping(uint256 => Airdrop1155) public airdrops1155;

    //Mapping de recipients para saber si pueden reclamar su airdrop
    mapping(address => bool) public recipients721;
    mapping(address => bool) public recipients1155;

    constructor() {
        admin = msg.sender;
    }

    //Funcion para agregar Airdrops al SC:

    //Pasamos un arreglo de Airdrop structs
    function addAirdrops721(Airdrop721[] memory _airdrops) external {
        require(msg.sender == admin, "only admin");
        //pasamos el counter como var local para no alterar el estado.
        uint256 _nextAirdropId = nextAirdropId721;
        //Bucle del arreglo de Airdrop structs.
        for (uint256 i = 0; i < _airdrops.length; i++) {
            //poblamos el mapping
            airdrops721[_nextAirdropId] = _airdrops[i];

            IERC721(_airdrops[i].tokenAddress).transferFrom(
                //El admin transfiere a este contrato
                msg.sender,
                address(this),
                _airdrops[i].tokenId
            );
            //aumentamos el counter.
            _nextAirdropId++;
        }
    }

    function addAirdrops1155(Airdrop1155[] memory _airdrops) external {
        require(msg.sender == admin, "only admin");
        //pasamos el counter como var local para no alterar el estado.
        uint256 _nextAirdropId = nextAirdropId1155;
        //Bucle del arreglo de Airdrop structs.
        for (uint256 i = 0; i < _airdrops.length; i++) {
            //poblamos el mapping
            airdrops1155[_nextAirdropId] = _airdrops[i];

            IERC1155(_airdrops[i].tokenAddress).safeTransferFrom(
                //El admin transfiere a este contrato
                msg.sender,
                address(this),
                _airdrops[i].tokenId,
                _airdrops[i].amount,
                "0x0"
            );
            //aumentamos el counter.
            _nextAirdropId++;
        }
    }

    //Funcion para agregar recipients 721
    function addRecipients721(address[] memory _recipients) external {
        require(msg.sender == admin, "only admin");
        for (uint256 i = 0; i < _recipients.length; i++) {
            recipients721[_recipients[i]] = true;
        }
    }

    //Funcion para remover recipients1155
    function removeRecipients721(address[] memory _recipients) external {
        require(msg.sender == admin, "only admin");
        for (uint256 i = 0; i < _recipients.length; i++) {
            recipients721[_recipients[i]] = false;
        }
    }

    //Funcion para agregar recipients 1155
    function addRecipients1155(address[] memory _recipients) external {
        require(msg.sender == admin, "only admin");
        for (uint256 i = 0; i < _recipients.length; i++) {
            recipients1155[_recipients[i]] = true;
        }
    }

    //Funcion para remover recipients1155
    function removeRecipients1155(address[] memory _recipients) external {
        require(msg.sender == admin, "only admin");
        for (uint256 i = 0; i < _recipients.length; i++) {
            recipients1155[_recipients[i]] = false;
        }
    }

    //Funcion usada por recipients para reclamar los airdrops.
    function claim721() external {
        //Tiene que estar dentro del arreglo de recipients para reclamar.
        require(recipients721[msg.sender] == true, "recipient not registered");
        //Una vez reclamado lo retiramos del arreglo.
        recipients721[msg.sender] = false;
        //Referenciamos el siguiente airdrop avail.
        Airdrop721 storage airdrop = airdrops721[nextAirdropId721];
        //Transferimos desde este SC hacia el MS
        IERC721(airdrop.tokenAddress).transferFrom(
            address(this),
            msg.sender,
            airdrop.tokenId
        );
        //Subimos el counter
        nextAirdropId721++;
    }

    function claim1155() external {
        //Tiene que estar dentro del arreglo de recipients para reclamar.
        require(recipients1155[msg.sender] == true, "recipient not registered");
        //Una vez reclamado lo retiramos del arreglo.
        recipients1155[msg.sender] = false;
        //Referenciamos el siguiente airdrop avail.
        Airdrop1155 storage airdrop = airdrops1155[nextAirdropId1155];
        //Transferimos desde este SC hacia el MS
        IERC1155(airdrop.tokenAddress).safeTransferFrom(
            address(this),
            msg.sender,
            airdrop.tokenId,
            airdrop.amount,
            "0x0"
        );
        //Subimos el counter
        nextAirdropId1155++;
    }
}