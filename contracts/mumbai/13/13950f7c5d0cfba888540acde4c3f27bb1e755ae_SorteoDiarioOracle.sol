/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/SorteoDiario.sol


pragma solidity >=0.8.18;

/*
 * @title TopacioSubscription
 * @dev Subscriptions Topacio - Julio Vinachi
 * ver 1.0.18 - 04-04-2023
 */



contract SorteoDiarioOracle is IERC721Receiver {
    struct Participantes {
        address[] wallets;
        uint256 nftId;
        uint256 winer_position;
    }

    struct HistoryWinners {
        address wallet;
        uint256 nftId;
        uint timestamp;
        string hash;
    }

    event newParticipation(address, uint256);

    // address, controlSorteo
    event newWinner(address, uint256);

    address private owner;
    uint8 public max_participaciones = 3;
    address[] public addressSubscriptors;

    uint256 blockStart;
    uint256 blockEnd;
    uint256 timestampStart;
    uint256 timestampEnd;
    uint256[] monthEvent;
    uint256 controlSorteo = 0;
    uint8 max_days = 30;
    uint256 public proximoSorteo = 0;
    uint256 public costParticipation = 1 ether;

    address payable public infrastructure =
        payable(0xc2133D7f29e8E2543ecB5B732b07Fe058C26778E);

    // when uint its a event date
    mapping(uint256 => Participantes) public sorteo;
    mapping(address => uint8) private _administradores;
    mapping(uint256 => HistoryWinners) public winners;

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() payable {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        _administradores[msg.sender] = 1;
        infrastructure = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not the owner contract");
        _;
    }

    modifier onlyAdministrator() {
        require(_administradores[msg.sender] > 0, "you are not administrator");
        _;
    }

    function updateInfrastructure(address _account) public onlyOwner {
        infrastructure = payable(_account);
    }

    /* 
    * implementacion pararecibir tokens solo el Owner puede depositar
    * previniendo que envien cualquier cosa y cualquier gente
    */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override onlyOwner returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function isAdmin() public view returns (bool) {
        return _administradores[msg.sender] > 0;
    }

    function addAdmin(address admin) public onlyOwner {
        _administradores[admin] = 1;
    }

    function removeAdmin(address admin) public onlyOwner {
        delete (_administradores[admin]);
    }

    function getBlock() public view returns (uint256) {
        return block.number;
    }

    function resetTime() public onlyAdministrator {
        proximoSorteo = block.timestamp + 1 days;
    }

    function lastSorteoTimesTamp() public view returns (uint256) {
        return proximoSorteo - 1 days;
    }

    // cantidad de sorteos
    function sorteoNumber() external view returns (uint256) {
        return controlSorteo + 1;
    }

    // busca cuantas participaciones tiene registradas en el dia
    function searchCountParticipationInSorteo(address wallet)
        external
        view
        returns (uint8)
    {
        uint8 participando = 0;

        for (uint256 i = 0; i < sorteo[controlSorteo].wallets.length; i++) {
            if (sorteo[controlSorteo].wallets[i] == wallet) {
                participando++;
            }
        }

        return participando;
    }

    // busca cuantas participaciones tiene registradas en OTROS dia
    function searchCountParticipationInOtherSorteo(
        address wallet,
        uint256 _controlSorteo
    ) external view returns (uint8) {
        uint8 participando = 0;

        for (uint256 i = 0; i < sorteo[_controlSorteo].wallets.length; i++) {
            if (sorteo[_controlSorteo].wallets[i] == wallet) {
                participando++;
            }
        }

        return participando;
    }

    // buscar en sorteos del dia actual
    function searchInCurrentSorteo(address wallet)
        external
        view
        returns (bool)
    {
        require(
            sorteo[controlSorteo].wallets.length > 0,
            "Aun no ha comenzado o no hay participantes."
        );

        bool participando = false;

        for (uint256 i = 0; i < sorteo[controlSorteo].wallets.length; i++) {
            if (sorteo[controlSorteo].wallets[i] == wallet) {
                participando = true;
            }
        }

        return participando;
    }

    // buscar en Otros sorteos
    function existInSorteo(address wallet, uint256 sorteoControl)
        external
        view
        returns (bool)
    {
        require(
            sorteo[sorteoControl].wallets.length > 0,
            "Aun no ha comenzado o no hay participantes."
        );

        bool participando = false;

        for (uint256 i = 0; i < sorteo[sorteoControl].wallets.length; i++) {
            if (sorteo[sorteoControl].wallets[i] == wallet) {
                participando = true;
            }
        }

        return participando;
    }

    // Agregando participante
    function addParticipanteToSorteo() public payable {
        // -- primero que no haya alcanzado el maximo de participaciones permitidas
        uint8 partticipaciones = this.searchCountParticipationInSorteo(
            msg.sender
        );
        require(
            partticipaciones < max_participaciones,
            "Alcanzo el maximo de participaciones permitidas."
        );
        require(msg.value == costParticipation, "Cantidad incorrecta");

        // -- pago
        payable(infrastructure).transfer(costParticipation);

        // -- agregando a wallets que participaran en el dia
        sorteo[controlSorteo].wallets.push(msg.sender);

        if (proximoSorteo == 0) {
            proximoSorteo = block.timestamp + 1 days;
        }

        emit newParticipation(msg.sender, costParticipation);
    }

    function updateCostParticipation(uint256 _costo) public onlyAdministrator {
        costParticipation = _costo;
    }

    function setWinnerMintOracle(uint256 nftId, string memory hash_fragment)
        external
        onlyAdministrator
    {
        require(sorteo[controlSorteo].nftId == 0, "need nftId no be initialized");
        require(
            winners[controlSorteo].wallet != address(0),
            "winner until now no set"
        );

        sorteo[controlSorteo].nftId = nftId;
        winners[controlSorteo].nftId = nftId;
        winners[controlSorteo].hash = hash_fragment;
        winners[controlSorteo].timestamp = block.timestamp;
        emit newWinner(winners[controlSorteo].wallet, controlSorteo);        
        controlSorteo++;
        proximoSorteo = block.timestamp + 1 days;
    }

    function selectWinnerV2()
        external
        payable
        onlyAdministrator
        returns (address)
    {
        uint256 longitudParticipantes = sorteo[controlSorteo].wallets.length;

        require(longitudParticipantes > 0, "No hay participantes");

        uint256 winner = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)
            )
        ) % longitudParticipantes;

        sorteo[controlSorteo].winer_position = winner;
        address winnerAddress = sorteo[controlSorteo].wallets[winner];

        // Guardando en el Historico de winners
        winners[controlSorteo].wallet = winnerAddress;
        winners[controlSorteo].timestamp = block.timestamp;

        // sorteo[controlSorteo].nftId =
        // winners[controlSorteo].hash = hash_fragment;

        return winnerAddress;
    }

    function existWinnerSelected() external view returns (address) {
        return winners[controlSorteo].wallet;
    }

    function getSorteoNumber() external view returns (uint256) {
        return controlSorteo;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function changeMaximoParticipaciones(uint8 _max) public onlyAdministrator {
        max_participaciones = _max;
    }

    function getParticipantsInDay() external view returns (address[] memory) {
        return sorteo[controlSorteo].wallets;
    }

    function getAmmountParticipantsInDay() external view returns (uint256) {
        return sorteo[controlSorteo].wallets.length;
    }
}