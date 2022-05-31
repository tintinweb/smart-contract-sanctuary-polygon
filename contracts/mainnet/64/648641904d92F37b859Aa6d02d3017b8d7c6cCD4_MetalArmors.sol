// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ArmorTokensMetadata.sol";
import "./MetalArmorId.sol";
import "./TokenId.sol";

interface IMetalApe {
    function getMetalApeByPairing(uint256 _metalApeTokenId)
        external
        view
        returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function totalSupply() external returns (uint256);

    function mintMetalApe(address _recipient) external returns (uint256 id);

    function mintMetalApeFromArmors(address _recipient)
        external
        returns (uint256 id);

    function mintMetalApeThroughPairing(
        uint256 _leftPairId,
        uint256 _rightPairId,
        address _targetAddress,
        address _itemAddress,
        uint256[] memory _itemIds
    ) external returns (uint256 newMetalApeId);

    function equipCompleteSetEquipment(
        uint256 _tokenId,
        address[] memory _itemAddresses,
        uint256[] memory _itemIds
    ) external;

    function equipFromArmorsContract(
        uint256 _tokenId,
        address[] memory _itemAddresses,
        uint256[] memory _itemIds
    ) external;

    function createEquipRecord(
        uint256 _tokenId,
        address[] memory _itemAddresses,
        uint256[] memory _itemIds
    ) external;
}

contract MetalArmors is Ownable, ERC1155, ArmorTokensMetadata {
    using SafeMath for uint16;
    using SafeMath for uint256;

    // The ChubbyApe contract
    IERC721Enumerable public chubbyApe;
    IMetalApe public metalApe;
    address public MetalArmorLogicAddress;

    uint256 public declareCount = 0;

    uint256 public declareSeed = 0;

    bool public saleIsActive = true;

    uint32[2] SSR_Threshold_Multiplier = [2500, 350];
    uint32[2] UR_Threshold_Multiplier = [7500, 1113];
    uint32[2] SR_Threshold_Multiplier = [15000, 2085];
    uint32[2] R_Threshold_Multiplier = [30000, 4320];
    uint32[2] N_Threshold_Multiplier = [45000, 5175];

    uint8[][] private rankIndexMap = [
        [0, 1], // 0 Carbon steel
        [2, 3], // 1 Black steel
        [4, 5], // 2 Platinum
        [6, 7], // 3 Original
        [8, 9] // 4 Scratched
    ];

    uint8[][] private setTitle_Index = [
        [0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    ];

    modifier onlyMetalArmorLogicAddress() {
        require(
            msg.sender == MetalArmorLogicAddress,
            "Not MetalArmorLogic_contract"
        );
        _;
    }

    modifier checkEquipmentType(uint256[] memory ids) {
        require(TokenId.fromId(ids[0]) == LEFTARM, "Must be left arm");
        require(TokenId.fromId(ids[1]) == MASK, "Must be mask");
        require(TokenId.fromId(ids[2]) == ARMOR, "Must be armor");
        require(TokenId.fromId(ids[3]) == LEFTLEG, "Must be left leg");
        require(TokenId.fromId(ids[4]) == RIGHTARM, "Must be right arm");
        require(TokenId.fromId(ids[5]) == RIGHTLEG, "Must be right leg");
        _;
    }

    constructor(string memory _baseURI)
        ERC1155("")
        ArmorTokensMetadata(_baseURI)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return
            interfaceId == MetalArmorId.INTERFACE_ID ||
            super.supportsInterface(interfaceId);
    }

    function getTotalSupply() public view returns (uint256) {
        return declareCount;
    }

    function _declare(address to) internal returns (uint256[] memory ids) {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        uint256[] memory amounts = new uint256[](6);
        ids = new uint256[](6);

        for (uint256 i = 0; i < ids.length; i++) {
            ids[0] = obtainTokenID(LEFTARM, declareSeed + LEFTARM);
            ids[1] = obtainTokenID(MASK, declareSeed + MASK);
            ids[2] = obtainTokenID(ARMOR, declareSeed + ARMOR);
            ids[3] = obtainTokenID(LEFTLEG, declareSeed + LEFTLEG);
            ids[4] = obtainTokenID(RIGHTARM, declareSeed + RIGHTARM);
            ids[5] = obtainTokenID(RIGHTLEG, declareSeed + RIGHTLEG);

            require(
                ids.length == amounts.length,
                "ERC1155: ids and amounts length mismatch"
            );

            amounts[i] = 1;
            _balances[ids[i]][to] += 1;

            // declared quantities
            declareCount += 6;
        }
        emit TransferBatch(operator, address(0), to, ids, amounts);

        // Update Seed
        uint256 rand = random(declareSeed);
        declareSeed = rand;

        return ids;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenURI(tokenId);
    }

    //** Provided to users who hold ChubbyApe token to mint */
    function mintChubbyApeEquipment(address _chubbyApeOwner)
        external
        onlyMetalArmorLogicAddress
        returns (uint256[] memory ids)
    {
        require(saleIsActive, "Mint is not active");

        return _declare(_chubbyApeOwner);
    }

    //** Pay to mint armors */
    function mintChubbyApeEquipments(uint256 _amount, address _recipient)
        external
        onlyMetalArmorLogicAddress
    {
        require(saleIsActive, "Mint is not active");
        require(
            _amount > 0,
            "Number of tokens can not be less than or equal to 0"
        );

        for (uint256 i = 0; i < _amount; i++) {
            _declare(_recipient);
        }
    }

    uint16 public exchangeArmorLimit = 2;
    uint16 public exchangeApeLimit = 2;

    function setexchangeLimit(
        uint16 _exchangeArmorLimit,
        uint16 _exchangeApeLimit
    ) public onlyOwner {
        exchangeArmorLimit = _exchangeArmorLimit;
        exchangeApeLimit = _exchangeApeLimit;
    }

    mapping(uint256 => uint16) public mintedArmorCount;
    mapping(uint256 => uint16) public mintedApeCount;

    // Create
    mapping(uint256 => uint16) public exchangeArmorCount;
    mapping(uint256 => uint16) public exchangeApeCount;

    function getExchangeCount(uint256 _tokenId)
        public
        view
        returns (uint16 _exchangeACount, uint16 _exchangePCount)
    {
        return (exchangeArmorCount[_tokenId], exchangeApeCount[_tokenId]);
    }

    function getExchangeApeCount(uint256 chubbyApeId)
        external
        view
        returns (uint16 _exchangeApeCount)
    {
        return exchangeApeCount[chubbyApeId];
    }

    function addExchangeApeCountForMetalApe(uint256 chubbyApeId) external {
        require(_msgSender() == address(metalApe), "Must Metal Ape Contract");
        exchangeApeCount[chubbyApeId] = exchangeApeCount[chubbyApeId] + 1;
    }

    function CreateArmorAndMetalApe(uint256 chubbyApeId)
        public
        returns (uint256 metalApeIDs, uint256[] memory idss)
    {
        require((block.timestamp > FreeStart && FreeEnd > block.timestamp));

        require(
            msg.sender == chubbyApe.ownerOf(chubbyApeId),
            "Must own Chubby Ape token"
        ); // Chubby Ape owner check

        require(
            exchangeArmorCount[chubbyApeId] < exchangeArmorLimit,
            "MMA exchange armor check failed"
        ); //Limit check

        require(
            exchangeApeCount[chubbyApeId] < exchangeApeLimit,
            "MMA exchange ape check failed"
        ); //Limit check

        mintedArmorCount[chubbyApeId] = mintedArmorCount[chubbyApeId] + 1;
        mintedApeCount[chubbyApeId] = mintedApeCount[chubbyApeId] + 1;

        // Add Armor exchange
        exchangeArmorCount[chubbyApeId] = exchangeArmorCount[chubbyApeId] + 1;

        // Add Ape exchange
        exchangeApeCount[chubbyApeId] = exchangeApeCount[chubbyApeId] + 1;

        // Mint Ape
        uint256 metalApeID = IMetalApe(metalApe).mintMetalApeFromArmors(
            msg.sender
        );

        // Mint Armors
        uint256[] memory ids = _declare(address(IMetalApe(metalApe)));

        // // equip to MetalAPE contract
        address[] memory eqpArray = new address[](6);
        eqpArray[0] = address(this);
        eqpArray[1] = address(this);
        eqpArray[2] = address(this);
        eqpArray[3] = address(this);
        eqpArray[4] = address(this);
        eqpArray[5] = address(this);

        IMetalApe(metalApe).createEquipRecord(metalApeID, eqpArray, ids);

        metalApeIDs = metalApeID;
        idss = ids;

        // send equp
        return (metalApeIDs, idss);
    }

    uint256 FreeStart;
    uint256 FreeEnd;

    function SetPeriod(
        uint8 _type,
        uint256 _start,
        uint256 _end
    ) public onlyOwner {
        //Type 1 is ChubbyFreeMint
        if (_type == 1) {
            FreeStart = _start;
            FreeEnd = _end;
        }
    }

    // partIndex index 0 ~ 5
    function obtainTokenID(uint256 _partIndex, uint256 _declareSeed)
        internal
        view
        returns (uint16)
    {
        uint256 randOrg = random(_declareSeed);
        uint32 rand = uint32(randOrg % 1000001);

        uint256 greatness = rand; //1-1000000

        uint8 rankCheckPlus = 0; //0:plus, 1:normal
        uint8 setCkeck = 0; //Set Index

        // get material
        uint8 materialIndex = 0;

        if (greatness <= 25000) {
            // SSR+, SSR

            materialIndex = 0;

            uint8[2] memory valueCheck = getRankCheckPlus_setCkeck(
                greatness,
                SSR_Threshold_Multiplier[0],
                SSR_Threshold_Multiplier[1]
            );
            rankCheckPlus = valueCheck[0];
            setCkeck = valueCheck[1];
        } else if (greatness <= 100000) {
            // UR+, UR
            materialIndex = 1;

            uint8[2] memory valueCheck = getRankCheckPlus_setCkeck(
                greatness,
                25000 + UR_Threshold_Multiplier[0],
                25000 + UR_Threshold_Multiplier[1]
            );
            rankCheckPlus = valueCheck[0];
            setCkeck = valueCheck[1];
        } else if (greatness <= 250000) {
            // SR+, SR
            materialIndex = 2;

            uint8[2] memory valueCheck = getRankCheckPlus_setCkeck(
                greatness,
                100000 + SR_Threshold_Multiplier[0],
                100000 + SR_Threshold_Multiplier[1]
            );
            rankCheckPlus = valueCheck[0];
            setCkeck = valueCheck[1];
        } else if (greatness <= 550000) {
            // R
            materialIndex = 3;

            uint8[2] memory valueCheck = getRankCheckPlus_setCkeck(
                greatness,
                250000 + R_Threshold_Multiplier[0],
                250000 + R_Threshold_Multiplier[1]
            );
            rankCheckPlus = valueCheck[0];
            setCkeck = valueCheck[1];
        } else {
            // N
            materialIndex = 4;

            uint8[2] memory valueCheck = getRankCheckPlus_setCkeck(
                greatness,
                550000 + N_Threshold_Multiplier[0],
                550000 + N_Threshold_Multiplier[1]
            );
            rankCheckPlus = valueCheck[0];
            setCkeck = valueCheck[1];
        }

        uint8 setIndex = setTitle_Index[rankCheckPlus][setCkeck];

        return
            getArmorTokenID(
                uint16(_partIndex),
                materialIndex,
                rankCheckPlus,
                setIndex
            );
    }

    /**---------------------
    Setting
     *----------------------/  
     */
    function SetInterfaceAddress(
        address _chubbyApeAddress,
        address _metalApeAddress,
        address _MetalArmorLogicAddress
    ) public onlyOwner {
        chubbyApe = IERC721Enumerable(_chubbyApeAddress);
        metalApe = IMetalApe(_metalApeAddress);
        MetalArmorLogicAddress = _MetalArmorLogicAddress;
    }

    function switchSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setThresholdMultiplier(uint8 _type, uint32[2] memory _Multiplier)
        public
        onlyOwner
    {
        if (_type == 1) {
            SSR_Threshold_Multiplier = _Multiplier;
        }
        if (_type == 2) {
            UR_Threshold_Multiplier = _Multiplier;
        }
        if (_type == 3) {
            SR_Threshold_Multiplier = _Multiplier;
        }
        if (_type == 4) {
            R_Threshold_Multiplier = _Multiplier;
        }
        if (_type == 5) {
            N_Threshold_Multiplier = _Multiplier;
        }
    }

    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    function getArmorTokenID(
        uint16 partIndex,
        uint16 materialIndex,
        uint16 rankCheckPlus,
        uint16 setIndex
    ) internal pure returns (uint16) {
        uint16 partBase = uint16(partIndex.mul(100));
        uint16 materialBase = uint16(materialIndex.mul(20));
        uint16 rankCheckBase = rankCheckPlus == 0 ? 0 : 5;
        return partBase + materialBase + rankCheckBase + setIndex + 1;
    }

    function getRankCheckPlus_setCkeck(
        uint256 greatness,
        uint32 Plushreshold,
        uint32 PlusTopThreshold
    ) internal pure returns (uint8[2] memory) {
        uint8 rankCheckPlus = 0;
        uint8 setCkeck = 0;
        if (greatness <= Plushreshold) {
            // Get Plus Set
            if (greatness <= PlusTopThreshold) {
                // Get Plus top, Index: 0
                rankCheckPlus = 0;
                setCkeck = 0;
            } else {
                //  Equal chance of Plus Set, but not Plus Top ,Index: 1~4
                rankCheckPlus = 0;
                setCkeck = uint8((greatness % 4)) + 1;
            }
        } else {
            // Not Plus set , 0~14
            rankCheckPlus = 1;
            setCkeck = uint8(greatness % 15);
        }

        return [rankCheckPlus, setCkeck];
    }

    function getTokenBalance(uint256 _tokenId, address owner)
        external
        view
        returns (uint256)
    {
        ERC1155 token = ERC1155(address(this));
        return token.balanceOf(owner, _tokenId);
    }

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 accountBalance = _balances[id][account];
        require(
            accountBalance >= amount,
            "ERC1155: burn amount exceeds balance"
        );
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(
                accountBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library TokenId {
    ///   token id  to item type (leftArm, mask etc.)
    function fromId(uint256 tokenID) internal pure returns (uint256 itemType) {
        uint8 partIndex = 0;
        if (tokenID < 101) {
            partIndex = 0;
        } else if (tokenID < 201) {
            partIndex = 1;
        } else if (tokenID < 301) {
            partIndex = 2;
        } else if (tokenID < 401) {
            partIndex = 3;
        } else if (tokenID < 501) {
            partIndex = 4;
        } else if (tokenID < 601) {
            partIndex = 5;
        }
        return partIndex;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

library MetalArmorId {
    bytes4 internal constant INTERFACE_ID = 0xd35e2fbd;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IMetalArmor {
    function itemTypeFor(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ApeEquipments.sol";
import "./TokenId.sol";
import "./IMetalArmor.sol";

struct ItemIds {
    uint256 mask;
    uint256 leftArm;
    uint256 rightArm;
    uint256 armor;
    uint256 leftLeg;
    uint256 rightLeg;
}

struct ItemNames {
    string mask;
    string leftArm;
    string rightArm;
    string armor;
    string leftLeg;
    string rightLeg;
}

/// @title Helper contract for generating ERC-1155 token ids and descriptions for
/// the individual items inside a ChubbyMetalArmor.
/// @author ChubbyApe
/// @dev Inherit from this contract and use it to generate metadata for your tokens
contract ArmorTokensMetadata is IMetalArmor, ApeEquipments, Ownable {
    string[] internal itemTypes = [
        "leftArm",
        "mask",
        "armor",
        "leftLeg",
        "rightArm",
        "rightLeg"
    ];

    string public baseURI;

    constructor(string memory _baseURI) {
        baseURI = _baseURI;
    }

    function name() external pure returns (string memory) {
        return "CMAT";
    }

    function symbol() external pure returns (string memory) {
        return "CMAEP";
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory base = baseURI;
        return string(abi.encodePacked(base, tokenId));
    }

    function itemTypeFor(uint256 id)
        external
        pure
        override
        returns (string memory)
    {
        uint256 _itemType = TokenId.fromId(id);
        return
            ["leftArm", "mask", "armor", "leftLeg", "rightArm", "rightLeg"][
                _itemType
            ];
    }
}

/**
 *Submitted for verification at Etherscan.io on 2021-08-30
 */

// SPDX-License-Identifier: Unlicense

/*

    ChubbyMetalArmor.sol

    This is a utility contract to make it easier for other
    contracts to work with ChubbyMetalArmor properties.

    To get an array of attributes that correspond to the item.

    The return format is:

    uint256[5] =>
        [0] = Item ID
        [1] = Set ID  
        [2] = Material ID 
        [3] = Rarity ID 

    See the item and attribute tables below for corresponding IDs. 
*/

pragma solidity ^0.8.0;

contract ApeEquipments {
 
    uint256 internal constant LEFTARM = 0x0;
    uint256 internal constant MASK = 0x1;
    uint256 internal constant ARMOR = 0x2;
    uint256 internal constant LEFTLEG = 0x3;
    uint256 internal constant RIGHTARM = 0x4;
    uint256 internal constant RIGHTLEG = 0x5;


    string[] internal maskArmor = [
        "Mask" // 0
    ];
    uint256 constant maskLength = 1;

    string[] internal leftArmArmor = [
        "Left Arm" // 1
    ];
    uint256 constant leftArmLength = 1;

    string[] internal rightArmArmor = [
        "Right Arm" // 1
    ];
    uint256 constant rightArmLength = 1;

    string[] internal armorArmor = [
        "Armor" // 1
    ];
    uint256 constant armorLength = 1;

    string[] internal leftLegArmor = [
        "Left Leg" // 1
    ];
    uint256 constant leftLegLength = 1;

    string[] internal rightLegArmor = [
        "Right Leg" // 1
    ];
    uint256 constant rightLegLength = 1;

    string[] internal rarity = [
        "SSR+", // 0
        "SSR", // 1
        "UR+", // 2
        "UR", // 3
        "SR+", // 4
        "SR", // 5
        "R+", // 6
        "R", // 7
        "N+", // 8
        "N" // 9
    ];
    string[] internal rarityTitle = [
        "Superior Super Rare", // 0
        "Ultra Rare", // 1
        "Super Rare", // 2
        "Rare", // 3
        "Normal" // 4
    ];
    uint256 constant rarityLength = 5;

    string[] internal set = [
        "Fire Dragon", // 0
        "Boom", // 1
        "Hellfire", // 2
        "Blaze", // 3
        "Scorching Sun", // 4
        "Meteorite", // 5
        "Thunderbolt", // 6
        "Angel's Blessing", // 7
        "Beam", // 8
        "Electromagnetic", // 9
        "Shark", // 10
        "Gladiator", // 11
        "Vulcan", // 12
        "Night Rabbit", // 13
        "Crab horn", // 14
        "Soil", // 15
        "Roar", // 16
        "Nuclear", // 17
        "Sun", // 18
        "Demon" // 19
    ];
    uint256 constant setLength = 20;
    uint16[] internal setRarityArray = [450, 300, 150, 75, 25];

    string[] internal material = [
        "Carbon steel", // 0
        "Black steel", // 1
        "Platinum", // 2
        "Original", // 3
        "Scratched" // 4
    ];
    uint256 constant materialLength = 5;
    uint16[] internal materialRarityArray = [450, 300, 150, 75, 25];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function maskComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "MASK", maskLength);
    }

    function leftArmComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "LEFTARM", leftArmLength);
    }

    function rightArmComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "RIGHTARM", rightArmLength);
    }

    function armorComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "ARMOR", armorLength);
    }

    function leftLegComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "LEFTLEG", leftLegLength);
    }

    function rightLegComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(tokenId, "RIGHTLEG", rightLegLength);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        uint256 sourceArrayLength
    ) internal pure returns (uint256[5] memory) {
        uint256[5] memory components;

        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );

        components[0] = rand % sourceArrayLength; // base item

        uint256 greatness = (rand % 1000) + 1; //1-1000

        // Rarity
        uint256 Rarity = getGreatness(greatness, 300, 150, 75, 25);
        components[1] = Rarity;
        components[2] = Rarity;

        return components;
    }

    //Get greatness
    function getGreatness(
        uint256 greatness,
        uint16 r,
        uint16 sr,
        uint16 ur,
        uint16 ssr
    ) internal pure returns (uint256 greatnessResult) {
        if (greatness <= ssr) {
            greatnessResult = 0;
        } else if (greatness <= ur) {
            greatnessResult = 1;
        } else if (greatness <= sr) {
            greatnessResult = 2;
        } else if (greatness <= r) {
            greatnessResult = 3;
        } else {
            greatnessResult = 4;
        }

        return greatnessResult;
    }

    // TODO: This costs 2.5k gas per invocation. We call it a lot when minting.
    // How can this be improved?
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}